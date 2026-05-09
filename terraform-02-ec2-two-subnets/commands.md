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

## Init and Validation

```bash
# 작업 디렉토리를 초기화하고 AWS 프로바이더를 다운로드합니다.
terraform init

# Terraform 파일을 일관된 형식으로 정렬합니다.
terraform fmt

# 플랜 전에 구성 문법을 검증합니다.
terraform validate
```

Key output:
```
Initializing provider plugins...
- Installing hashicorp/aws v5.100.0...
- Installed hashicorp/aws v5.100.0 (signed by HashiCorp)
Terraform has been successfully initialized!

Success! The configuration is valid.
```

Interpretation:
AWS Provider v5.100.0이 설치되었고 구성 문법이 유효하다. `terraform fmt`는 포맷 변경이 없으면 아무 출력도 내지 않는다.

---

## Saved Plan

```bash
# 나중에 검토된 플랜을 그대로 적용할 수 있도록 실행 플랜을 파일에 저장합니다.
terraform plan -out plan.out

# 저장된 플랜 파일을 사람이 읽을 수 있는 형태로 출력합니다.
terraform show plan.out
```

Key output:
```
Plan: 3 to add, 0 to change, 0 to destroy.

  # aws_instance.web["web-a"] will be created
  + resource "aws_instance" "web" {
      + instance_type = "t3.micro"
      + subnet_id     = "subnet-0b325a3a157bfff42"
    }

  # aws_instance.web["web-b"] will be created
  + resource "aws_instance" "web" {
      + instance_type = "t3.micro"
      + subnet_id     = "subnet-0907c242196e43f14"
    }

  # aws_security_group.web will be created

Changes to Outputs:
  + selected_availability_zones = ["us-east-1a", "us-east-1b"]
  + selected_subnet_ids         = ["subnet-0b325a3a157bfff42", "subnet-0907c242196e43f14"]

Saved the plan to: plan.out
```

Interpretation:
`for_each`가 `instance_subnet_map`을 순회하여 `web-a`와 `web-b` 두 인스턴스를 생성한다. 각각 `us-east-1a`와 `us-east-1b`의 서로 다른 서브넷에 배치된다. `-out plan.out`으로 저장된 플랜은 apply 시 재계산 없이 그대로 실행되어 검토한 내용과 동일한 변경이 보장된다.

---

## Apply and Outputs

```bash
# 새 플랜을 재계산하지 않고 저장된 플랜을 그대로 적용합니다.
terraform apply plan.out

# 선택된 서브넷 ID와 인스턴스 IP를 포함한 모든 output을 읽습니다.
terraform output
```

Key output:
```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:
instance_ids = {
  "web-a" = "i-00ecae2a36197d93f"
  "web-b" = "i-073c7b6a7665ea08c"
}
instance_public_dns = {
  "web-a" = "ec2-98-92-238-10.compute-1.amazonaws.com"
  "web-b" = "ec2-3-87-223-203.compute-1.amazonaws.com"
}
instance_public_ips = {
  "web-a" = "98.92.238.10"
  "web-b" = "3.87.223.203"
}
selected_availability_zones = tolist(["us-east-1a", "us-east-1b"])
selected_subnet_ids = ["subnet-0b325a3a157bfff42", "subnet-0907c242196e43f14"]
```

Interpretation:
EC2 2개와 Security Group 1개가 성공적으로 생성되었다. `web-a`는 us-east-1a, `web-b`는 us-east-1b에 배치되어 서로 다른 AZ에 분산 배포가 확인되었다. 각 인스턴스에 curl로 접속한 결과 서로 다른 서버 이름으로 응답했다.

```bash
curl "http://98.92.238.10" && echo "---" && curl "http://3.87.223.203"
```

```
<h1>Terraform Example 02</h1>
<p>Server Name: web-a</p>   ← 98.92.238.10 응답

<h1>Terraform Example 02</h1>
<p>Server Name: web-b</p>   ← 3.87.223.203 응답
```

`for_each`와 `templatefile()`의 `server_name = each.key` 주입이 정상 동작하여 두 인스턴스가 서로 다른 이름으로 응답함을 확인했다.

---

## State Inspection

```bash
# Terraform이 현재 state 파일에서 추적 중인 모든 객체를 나열합니다.
terraform state list

# 임시 표현식 검사를 위해 Terraform 콘솔을 엽니다.
terraform console
```

Useful console expressions:
```text
local.instance_subnet_map
keys(aws_instance.web)
values(aws_instance.web)[*].public_ip
```

Key output:
```
data.aws_ssm_parameter.al2023_ami
data.aws_subnet.default_vpc["subnet-063f9ccf5facc7d21"]
data.aws_subnet.default_vpc["subnet-0907c242196e43f14"]
data.aws_subnet.default_vpc["subnet-090b0320b9f8cd3d8"]
data.aws_subnet.default_vpc["subnet-0b325a3a157bfff42"]
data.aws_subnet.default_vpc["subnet-0ce5188ddee11adfe"]
data.aws_subnet.default_vpc["subnet-0eb7510f45442d602"]
data.aws_subnets.default_vpc
data.aws_vpc.default
aws_instance.web["web-a"]
aws_instance.web["web-b"]
aws_security_group.web
```

Interpretation:
`for_each`를 사용하면 리소스가 `aws_instance.web["web-a"]`, `aws_instance.web["web-b"]`처럼 키가 붙어 state에 독립적으로 저장된다. 과제 01의 단순 `aws_instance.web`과 달리 각 인스턴스를 개별적으로 수정하거나 삭제할 수 있다.

---

## Cleanup

```bash
terraform destroy -auto-approve
```

Key output:
```
aws_instance.web["web-a"]: Destroying... [id=i-00ecae2a36197d93f]
aws_instance.web["web-b"]: Destroying... [id=i-073c7b6a7665ea08c]
aws_instance.web["web-a"]: Destruction complete after 30s
aws_instance.web["web-b"]: Destruction complete after 40s
aws_security_group.web: Destroying... [id=sg-0d145d5f8c527d5f7]
aws_security_group.web: Destruction complete after 0s

Destroy complete! Resources: 3 destroyed.
```

Interpretation:
`web-a`와 `web-b` 두 인스턴스가 병렬로 동시에 삭제되었다. `for_each`로 생성된 리소스는 삭제 시에도 병렬 처리되어 단일 인스턴스보다 빠르게 완료된다. EC2가 모두 종료된 후 Security Group이 삭제되었다.

---

## Credential Handling Note

```text
Store AWS Academy temporary credentials in environment variables only.
Do not put AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, or AWS_SESSION_TOKEN into terraform.tfvars.
```
