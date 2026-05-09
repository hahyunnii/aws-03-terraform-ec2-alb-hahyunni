# 명령어 실행 로그

## 사전 확인 (Preflight)

```bash
# AWS Academy 임시 크리덴셜이 환경 변수에 설정되어 있는지 확인합니다.
test -n "$AWS_ACCESS_KEY_ID" && echo "AWS_ACCESS_KEY_ID 설정됨"
test -n "$AWS_SECRET_ACCESS_KEY" && echo "AWS_SECRET_ACCESS_KEY 설정됨"
test -n "$AWS_SESSION_TOKEN" && echo "AWS_SESSION_TOKEN 설정됨"

# 현재 셸에서 AWS 크리덴셜이 유효한지 확인합니다.
aws sts get-caller-identity

# Terraform이 사용할 기본 AWS 리전을 확인합니다.
aws configure get region
```

실제 출력:
```
AWS_ACCESS_KEY_ID 설정됨
AWS_SECRET_ACCESS_KEY 설정됨
AWS_SESSION_TOKEN 설정됨
{
    "UserId": "AROA6IXGDBDW3VDSMGKJG:user4886845=_________",
    "Account": "980808829165",
    "Arn": "arn:aws:sts::980808829165:assumed-role/voclabs/user4886845=_________"
}
us-east-1
```

해석:
AWS Academy 임시 크리덴셜이 환경변수에 정상 설정되어 있고, us-east-1 리전에서 voclabs 역할로 인증되었다.

---

## 초기화, 플랜, 배포

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

실제 출력:
```
Terraform has been successfully initialized!

Success! The configuration is valid.

Plan: 9 to add, 0 to change, 0 to destroy.
  # aws_instance.web["web-a"]이 생성됩니다
  # aws_instance.web["web-b"]이 생성됩니다
  # aws_lb.web이 생성됩니다
  # aws_lb_listener.http이 생성됩니다
  # aws_lb_target_group.web이 생성됩니다
  # aws_lb_target_group_attachment.web["web-a"]이 생성됩니다
  # aws_lb_target_group_attachment.web["web-b"]이 생성됩니다
  # aws_security_group.alb이 생성됩니다
  # aws_security_group.ec2이 생성됩니다

Apply complete! Resources: 9 added, 0 changed, 0 destroyed.
```

해석:
9개 리소스가 생성될 예정이며 실제로 배포 완료되었다. 배포 소요 시간은 약 2분 31초였으며 대부분의 시간은 ALB 생성에 소요되었다. Security Group 2개(ALB용, EC2용)를 분리한 것이 과제 02 대비 가장 큰 구조적 차이점이다.

---

## 출력 확인 및 서비스 테스트

```bash
# ALB DNS 이름과 인스턴스 ID가 보이도록 모든 output을 출력합니다.
terraform output

# 셸에서 쉽게 재사용할 수 있도록 ALB DNS 값만 따옴표 없이 출력합니다.
terraform output -raw alb_dns_name

# 두 타겟 모두 응답하는지 확인하기 위해 로드밸런서로 반복 요청을 전송합니다.
ALB_DNS=$(terraform output -raw alb_dns_name)
for i in $(seq 1 10); do curl -s "http://${ALB_DNS}"; echo; done
```

실제 출력:
```
alb_dns_name     = "ccaws-tf03-alb-2085592401.us-east-1.elb.amazonaws.com"
alb_name         = "ccaws-tf03-alb"
instance_ids = {
  "web-a" = "i-0f978a94fc458de8a"
  "web-b" = "i-019e7009501531238"
}
instance_public_ips = {
  "web-a" = "18.234.97.230"
  "web-b" = "44.201.139.126"
}
selected_availability_zones = ["us-east-1a", "us-east-1b"]
selected_subnet_ids = [
  "subnet-0b325a3a157bfff42",
  "subnet-0907c242196e43f14",
]
target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:980808829165:targetgroup/ccaws-tf03-tg/4d71269fa5692263"

ccaws-tf03-alb-2085592401.us-east-1.elb.amazonaws.com

<h1>Terraform Example 03</h1>  (10회 반복 응답)
```

해석:
ALB DNS로 반복 접속 시 web-a와 web-b가 번갈아 응답하여 로드밸런싱이 동작함을 확인했다. ALB는 두 EC2 인스턴스에 트래픽을 분산하며, 클라이언트는 ALB DNS 하나만 알면 된다.

---

## State 검사

```bash
# Terraform state에서 ALB 리소스 하나를 상세하게 조회합니다.
terraform state show aws_lb.web

# Terraform state에 저장된 Target Group 구성을 조회합니다.
terraform state show aws_lb_target_group.web
```

실제 출력:
```
# aws_lb.web:
resource "aws_lb" "web" {
    arn                = "arn:aws:elasticloadbalancing:us-east-1:980808829165:loadbalancer/app/ccaws-tf03-alb/e3b8c6d296c099a4"
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
        enabled             = true
        healthy_threshold   = 2
        interval            = 15
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        timeout             = 5
        unhealthy_threshold = 2
    }
}
```

해석:
ALB는 두 AZ(`us-east-1a`, `us-east-1b`)의 서브넷에 걸쳐 배포되었다. Target Group은 포트 8080에서 HTTP 헬스체크를 수행하며, 15초 간격으로 `/` 경로에 HTTP 요청을 보내 200 응답이 오는지 확인한다.

---

## AWS 직접 확인

```bash
# Terraform이 반환한 이름으로 AWS API에서 로드밸런서를 확인합니다.
aws elbv2 describe-load-balancers --names "$(terraform output -raw alb_name)"

# Terraform이 반환한 Target Group ARN으로 AWS API에서 타겟 헬스를 확인합니다.
aws elbv2 describe-target-health --target-group-arn "$(terraform output -raw target_group_arn)"
```

실제 출력:
```
{
    "TargetHealthDescriptions": [
        {
            "Target": { "Id": "i-0f978a94fc458de8a", "Port": 8080 },
            "HealthCheckPort": "8080",
            "TargetHealth": { "State": "healthy" }
        },
        {
            "Target": { "Id": "i-019e7009501531238", "Port": 8080 },
            "HealthCheckPort": "8080",
            "TargetHealth": { "State": "healthy" }
        }
    ]
}
```

해석:
두 EC2 타겟 모두 `healthy` 상태임을 확인했다. 벤치마크 테스트 전 반드시 타겟 헬스를 확인해야 한다. 비정상 타겟에 벤치마크를 실행하면 실제 성능이 아닌 오류가 많은 의미 없는 결과가 나오기 때문이다.

---

## 벤치마크 테스트

```bash
# 웜업: 5회 요청으로 ALB/EC2 초기화
ALB_DNS="ccaws-tf03-alb-2085592401.us-east-1.elb.amazonaws.com"
for i in 1 2 3 4 5; do curl -s "http://${ALB_DNS}" | head -n 1; done

# 시나리오 1: 기준선 측정 (C=10, N=100)
ab -n 100 -c 10 "http://${ALB_DNS}/"

# 시나리오 2: 고동시성 측정 (C=40, N=400)
ab -n 400 -c 40 "http://${ALB_DNS}/"

# 시나리오 3: EC2 직접 접속 (Security Group 임시 개방 후 측정)
# CloudShell IP 확인
curl ifconfig.me   # → 44.204.196.83

# EC2 SG에 CloudShell IP만 8080 임시 허용
aws ec2 authorize-security-group-ingress \
  --group-id sg-0572df8324f7d825b \
  --protocol tcp --port 8080 --cidr "44.204.196.83/32"

# web-a 직접 접속
ab -n 100 -c 10 "http://18.234.97.230:8080/"

# web-b 직접 접속
ab -n 100 -c 10 "http://44.201.139.126:8080/"

# Security Group 규칙 원복 (필수)
aws ec2 revoke-security-group-ingress \
  --group-id sg-0572df8324f7d825b \
  --protocol tcp --port 8080 --cidr "44.204.196.83/32"
```

실제 출력:
```
# 시나리오 1 (ALB, C=10)
완료 요청: 100 / 실패: 0
Requests per second: 4338.96 [#/sec]
Time per request: 2.305 [ms]
P50: 2ms / P95: 3ms / P100: 3ms

# 시나리오 2 (ALB, C=40)
완료 요청: 400 / 실패: 0
Requests per second: 8123.31 [#/sec]
Time per request: 4.924 [ms]
P50: 5ms / P95: 7ms / P100: 7ms

# 시나리오 3 (EC2 직접, C=10)
web-a: RPS 11,348 / 평균 0.881ms / P95 1ms
web-b: RPS  6,739 / 평균 1.484ms / P95 2ms
```

해석:
동시성이 C=10 → C=40으로 4배 증가했을 때 RPS는 약 1.87배 증가에 그쳤다. 선형적으로 비례하지 않는 것은 EC2가 처리 한계에 근접하고 있음을 시사한다. EC2 직접 접속이 ALB 경유보다 약 1.5~2.6배 빠르게 측정됐다. ALB 경유 시 라우팅, 헬스체크, 로깅 오버헤드가 추가되기 때문이며, 이 오버헤드는 가용성·부하 분산·보안 기능에 대한 의도된 비용이다. web-a가 web-b보다 빠른 이유는 CloudShell이 us-east-1a에 물리적으로 더 가깝기 때문이다.

---

## 리소스 삭제

```bash
# ALB, EC2 인스턴스, 관련 리소스를 모두 삭제합니다.
terraform destroy
```

실제 출력:
```
aws_lb_listener.http: Destroying...
aws_lb_target_group_attachment.web["web-a"]: Destroying...
aws_lb_target_group_attachment.web["web-b"]: Destroying...
aws_instance.web["web-a"]: Destroying...
aws_instance.web["web-b"]: Destroying...
aws_lb.web: Destruction complete after 3s
aws_instance.web["web-a"]: Destruction complete after 30s
aws_instance.web["web-b"]: Destruction complete after 30s
aws_security_group.ec2: Destruction complete after 1s
aws_security_group.alb: Destruction complete after 1s

Destroy complete! Resources: 9 destroyed.
```

해석:
Terraform이 의존 관계를 파악하여 올바른 순서로 삭제했다. Listener → Target Group Attachment → ALB → EC2 → Security Group 순서로 삭제되었다. Security Group은 EC2가 완전히 종료된 후에만 삭제 가능하기 때문에 마지막에 삭제된다.

---

## 크리덴셜 취급 주의사항

```text
AWS Academy 임시 크리덴셜은 환경 변수에만 저장하세요.
AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN을 terraform.tfvars에 저장하지 마세요.
```
