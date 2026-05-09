# Commands Log

## Preflight

```bash
# AWS Academy 임시 크리덴셜이 환경 변수에 설정되어 있는지 확인합니다.
test -n "$AWS_ACCESS_KEY_ID" && echo "AWS_ACCESS_KEY_ID is set"
test -n "$AWS_SECRET_ACCESS_KEY" && echo "AWS_SECRET_ACCESS_KEY is set"
test -n "$AWS_SESSION_TOKEN" && echo "AWS_SESSION_TOKEN is set"

# 현재 셸에서 AWS 크리덴셜이 유효한지 확인합니다.
aws sts get-caller-identity

# Terraform이 사용할 기본 AWS 리전을 확인합니다.
aws configure get region
```

Key output:
```
AWS_ACCESS_KEY_ID is set
AWS_SECRET_ACCESS_KEY is set
AWS_SESSION_TOKEN is set
{
    "UserId": "AROA6IXGDBDW3VDSMGKJG:user4886845=_________",
    "Account": "980808829165",
    "Arn": "arn:aws:sts::980808829165:assumed-role/voclabs/user4886845=_________"
}
us-east-1
```

Interpretation:
AWS Academy 임시 크리덴셜이 환경변수에 정상 설정되어 있고, us-east-1 리전에서 voclabs 역할로 인증되었다.

---

## Init, Plan, and Apply

```bash
# 작업 디렉토리를 초기화하고 AWS 프로바이더를 설치합니다.
terraform init

# 검증 및 플랜 전에 형식을 정규화합니다.
terraform fmt

# 문법과 프로바이더/리소스 참조를 검사합니다.
terraform validate

# 검토된 실행 플랜을 파일에 저장합니다.
terraform plan -out plan.out

# 검토한 플랜을 그대로 적용합니다.
terraform apply plan.out
```

Key output:
```
Terraform has been successfully initialized!

Success! The configuration is valid.

Plan: 9 to add, 0 to change, 0 to destroy.
  # aws_instance.web["web-a"] will be created
  # aws_instance.web["web-b"] will be created
  # aws_lb.web will be created
  # aws_lb_listener.http will be created
  # aws_lb_target_group.web will be created
  # aws_lb_target_group_attachment.web["web-a"] will be created
  # aws_lb_target_group_attachment.web["web-b"] will be created
  # aws_security_group.alb will be created
  # aws_security_group.ec2 will be created

Apply complete! Resources: 9 added, 0 changed, 0 destroyed.
```

Interpretation:
9개 리소스가 생성될 예정이며 실제로 배포 완료되었다. 배포 소요 시간은 약 2분 31초였으며 대부분의 시간은 ALB 생성에 소요되었다. Security Group을 ALB용과 EC2용으로 분리한 것이 과제 02 대비 가장 큰 구조적 차이점이다.

---

## Outputs and Service Test

```bash
# ALB DNS 이름과 인스턴스 ID가 보이도록 모든 output을 출력합니다.
terraform output

# 셸에서 쉽게 재사용할 수 있도록 ALB DNS 값만 따옴표 없이 출력합니다.
terraform output -raw alb_dns_name

# 두 타겟 모두 응답하는지 확인하기 위해 로드밸런서로 반복 요청을 전송합니다.
ALB_DNS=$(terraform output -raw alb_dns_name)
for i in $(seq 1 5); do curl -s "http://${ALB_DNS}" | head -n 1; done
```

Key output:
```
alb_dns_name     = "ccaws-tf03-alb-2085592401.us-east-1.elb.amazonaws.com"
alb_name         = "ccaws-tf03-alb"
instance_ids = {
  "web-a" = "i-0f978a94fc458de8a"
  "web-b" = "i-019e7009501531238"
}
instance_public_ips = {
  "web-a" = "44.204.114.109"
  "web-b" = "13.220.158.32"
}
selected_availability_zones = ["us-east-1a", "us-east-1b"]
selected_subnet_ids = [
  "subnet-0b325a3a157bfff42",
  "subnet-0907c242196e43f14",
]
target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:980808829165:targetgroup/ccaws-tf03-tg/4d71269fa5692263"

ccaws-tf03-alb-2085592401.us-east-1.elb.amazonaws.com

<h1>Terraform Example 03</h1>
<h1>Terraform Example 03</h1>
<h1>Terraform Example 03</h1>
<h1>Terraform Example 03</h1>
<h1>Terraform Example 03</h1>
```

Interpretation:
ALB DNS로 5회 curl 요청 시 정상 응답이 확인되었다. 이 웜업 단계는 콜드 스타트 지연을 제거하여 안정적인 벤치마크 기준선을 확보하기 위한 필수 단계이다.

---

## State Inspection

```bash
# Terraform state에서 ALB 리소스 하나를 상세하게 조회합니다.
terraform state show aws_lb.web

# Terraform state에 저장된 Target Group 구성을 조회합니다.
terraform state show aws_lb_target_group.web
```

Key output:
```
# aws_lb.web:
resource "aws_lb" "web" {
    dns_name           = "ccaws-tf03-alb-2085592401.us-east-1.elb.amazonaws.com"
    internal           = false
    load_balancer_type = "application"
    name               = "ccaws-tf03-alb"
    security_groups    = ["sg-0e2f6871186b6eb67"]
    subnets            = ["subnet-0907c242196e43f14", "subnet-0b325a3a157bfff42"]
}

# aws_lb_target_group.web:
resource "aws_lb_target_group" "web" {
    name        = "ccaws-tf03-tg"
    port        = 8080
    protocol    = "HTTP"
    target_type = "instance"
    vpc_id      = "vpc-099a13dbc423e5700"
    health_check {
        interval  = 15
        matcher   = "200"
        path      = "/"
        port      = "traffic-port"
        timeout   = 5
    }
}
```

Interpretation:
ALB는 두 AZ(us-east-1a, us-east-1b)의 서브넷에 걸쳐 배포되었다. Target Group은 포트 8080에서 HTTP 헬스체크를 수행하며, 15초 간격으로 `/` 경로에 요청을 보내 200 응답이 오는지 확인한다.

---

## AWS Verification

```bash
# Terraform이 반환한 이름으로 AWS API에서 로드밸런서를 확인합니다.
aws elbv2 describe-load-balancers --names "$(terraform output -raw alb_name)"

# Terraform이 반환한 Target Group ARN으로 AWS API에서 타겟 헬스를 확인합니다.
aws elbv2 describe-target-health \
  --target-group-arn "$(terraform output -raw target_group_arn)" \
  --query 'TargetHealthDescriptions[*].{ID:Target.Id,State:TargetHealth.State}' \
  --output table
```

Key output:
```
------------------------------------
|       DescribeTargetHealth       |
+----------------------+-----------+
|          ID          |   State   |
+----------------------+-----------+
|  i-0f978a94fc458de8a |  healthy  |
|  i-019e7009501531238 |  healthy  |
+----------------------+-----------+
```

Interpretation:
두 EC2 타겟 모두 `healthy` 상태임을 확인했다. 벤치마크 시작 전 반드시 타겟 헬스를 확인해야 한다. 비정상 타겟에 벤치마크를 실행하면 실제 성능이 아닌 오류가 많은 의미 없는 결과가 나오기 때문이다.

---

## Raw ab Check

```bash
ab -n 100 -c 10 "http://${ALB_DNS}/"
```

Key output:
```
Complete requests:      100
Failed requests:        0
Requests per second:    6105.01 [#/sec] (mean)
Time per request:       1.638 [ms] (mean)

Percentage of the requests served within a certain time (ms)
  50%      1
  95%      2
 100%      3 (longest request)
```

Interpretation:
100개 요청 모두 성공(실패 0건). 처리량 6,105 req/s, 평균 지연 1.638ms, P95 2ms로 안정적인 기준선이 확인되었다. 평균 지연만으로는 이상값을 숨길 수 있으므로 P95를 함께 확인해야 한다.

---

## Benchmark Scenarios

### Scenario 1 — Baseline ALB

```bash
RESET_SUMMARY=true \
SCENARIO_NAME=baseline-alb \
REQUESTS=100 CONCURRENCY=10 \
TARGET_URL="http://${ALB_DNS}/" TARGET_LABEL=alb \
bash scripts/run-http-benchmark.sh
```

Key output:
```
[DONE] scenario=baseline-alb, target=alb, success=100, failed=0, avg=0.001000s, p95=0.002000s, rps=6105.01
```

Interpretation:
낮은 동시성(C=10)에서 기준 성능이 확립되었다. 실패 0건으로 두 타겟 모두 정상 라우팅 중임이 확인되었다. RPS 6,105, P95 2ms가 이후 모든 시나리오의 비교 기준점이 된다.

### Scenario 2 — Higher Concurrency ALB

```bash
SCENARIO_NAME=higher-concurrency-alb \
REQUESTS=400 CONCURRENCY=40 \
TARGET_URL="http://${ALB_DNS}/" TARGET_LABEL=alb \
bash scripts/run-http-benchmark.sh
```

Key output:
```
[DONE] scenario=higher-concurrency-alb, target=alb, success=400, failed=0, avg=0.005000s, p95=0.008000s, rps=7345.92
```

Interpretation:
동시성 4배 증가(C=10→C=40) 시 RPS는 6,105→7,345로 약 1.2배 증가에 그쳤다. 처리량이 동시성에 비례하지 않은 것은 EC2 백엔드가 처리 한계에 근접하고 있음을 나타낸다. P95 지연은 2ms→8ms로 4배 증가하여 꼬리 지연이 급격히 늘어났다. 실패는 여전히 0건으로 안정적인 구간 내에 있다.

### Scenario 3 — Direct EC2 Comparison (web-a)

```bash
# CloudShell IP 확인
curl ifconfig.me  # → 44.211.243.55

# EC2 SG 임시 개방
aws ec2 authorize-security-group-ingress \
  --group-id sg-0572df8324f7d825b \
  --protocol tcp --port 8080 --cidr "44.211.243.55/32"

SCENARIO_NAME=direct-compare \
REQUESTS=100 CONCURRENCY=10 \
TARGET_URL="http://44.204.114.109:8080/" TARGET_LABEL=direct-web-a \
bash scripts/run-http-benchmark.sh
```

Key output:
```
[DONE] scenario=direct-compare, target=direct-web-a, success=100, failed=0, avg=0.001000s, p95=0.001000s, rps=10890.87
```

Interpretation:
ALB 우회 시 RPS 10,890으로 ALB 경유(6,105) 대비 약 1.78배 빠르게 측정되었다. ALB 경유 시 라우팅·헬스체크·로깅 오버헤드가 추가되기 때문이다. 그러나 직접 접속이 더 빠르다고 ALB가 불필요한 것은 아니다 — ALB는 헬스 기반 라우팅, 부하 분산, TLS 종료, EC2 직접 접속 차단 기능을 제공한다.

### Scenario 3 — Direct EC2 Comparison (web-b)

```bash
SCENARIO_NAME=direct-compare-web-b \
REQUESTS=100 CONCURRENCY=10 \
TARGET_URL="http://13.220.158.32:8080/" TARGET_LABEL=direct-web-b \
bash scripts/run-http-benchmark.sh

# SG 원복 (필수)
aws ec2 revoke-security-group-ingress \
  --group-id sg-0572df8324f7d825b \
  --protocol tcp --port 8080 --cidr "44.211.243.55/32"
```

Key output:
```
[DONE] scenario=direct-compare-web-b, target=direct-web-b, success=100, failed=0, avg=0.001000s, p95=0.001000s, rps=7588.98
```

Interpretation:
web-b(7,588 RPS)가 web-a(10,890 RPS)보다 낮게 측정된 이유는 CloudShell이 us-east-1a에 물리적으로 더 가깝기 때문이다. 동일한 인스턴스 타입이라도 클라이언트와의 네트워크 거리에 따라 측정값이 달라질 수 있다.

---

## Summary CSV

```bash
cat results/summary.csv
```

Key output:
```
scenario,target,tool,requests,concurrency,success,failed,avg_time_sec,p95_time_sec,requests_per_sec
baseline-alb,alb,ab,100,10,100,0,0.001000,0.002000,6105.01
higher-concurrency-alb,alb,ab,400,40,400,0,0.005000,0.008000,7345.92
direct-compare,direct-web-a,ab,100,10,100,0,0.001000,0.001000,10890.87
direct-compare-web-b,direct-web-b,ab,100,10,100,0,0.001000,0.001000,7588.98
```

Interpretation:
4개 시나리오 모두 실패 0건으로 안정적인 결과가 수집되었다. 동시성 증가 시 RPS는 소폭 증가했으나 P95 지연은 4배 증가했다. EC2 직접 접속이 ALB 경유보다 빠르지만, ALB가 제공하는 가용성과 보안 기능을 고려하면 ALB 경유가 운영 환경에서 올바른 선택이다.

---

## Cleanup

```bash
terraform destroy -auto-approve
```

Key output:
```
aws_lb_listener.http: Destruction complete after 0s
aws_lb.web: Destruction complete after 26s
aws_instance.web["web-a"]: Destruction complete after 20s
aws_instance.web["web-b"]: Destruction complete after 30s
aws_security_group.ec2: Destruction complete after 1s
aws_security_group.alb: Destruction complete after 0s

Destroy complete! Resources: 9 destroyed.
```

Interpretation:
Terraform이 의존 관계를 파악하여 올바른 순서로 삭제했다. Listener → ALB → EC2 → Security Group 순서로 삭제되었다. Security Group은 EC2가 완전히 종료된 후에만 삭제 가능하기 때문에 마지막에 삭제된다.

---

## Credential Handling Note

```text
Store AWS Academy temporary credentials in environment variables only.
Do not put AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, or AWS_SESSION_TOKEN into terraform.tfvars.
```
