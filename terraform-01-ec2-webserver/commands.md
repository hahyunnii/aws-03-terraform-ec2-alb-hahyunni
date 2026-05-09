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

# Terraform이 설치되어 있는지 확인합니다.
terraform version
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
Terraform v1.15.1 on linux_amd64
```

해석:
AWS Academy 임시 크리덴셜이 환경변수에 정상 설정되어 있고, us-east-1 리전에서 voclabs 역할로 인증되었다. Terraform v1.15.1이 설치되어 있다.

---

## 초기화 및 포맷

```bash
# AWS 프로바이더 플러그인을 로컬 .terraform 디렉토리에 다운로드합니다.
terraform init

# Terraform 파일을 표준 형식으로 자동 정렬합니다.
terraform fmt
```

실제 출력:
```
Initializing provider plugins...
- Installing hashicorp/aws v5.100.0...
- Installed hashicorp/aws v5.100.0 (signed by HashiCorp)
Terraform has been successfully initialized!
```

해석:
AWS Provider v5.100.0이 `.terraform` 디렉토리에 다운로드되었다. `terraform fmt`는 포맷 변경이 없으면 아무 출력도 내지 않는다.

---

## 검증 및 플랜

```bash
# Terraform 문법과 프로바이더/리소스 참조를 검사합니다.
terraform validate

# 변경 사항을 적용하기 전에 생성될 리소스를 미리 확인합니다.
terraform plan
```

실제 출력:
```
Success! The configuration is valid.

Plan: 2 to add, 0 to change, 0 to destroy.

  # aws_instance.web이 생성됩니다
  + resource "aws_instance" "web" {
      + instance_type = "t3.micro"
      + subnet_id     = "subnet-063f9ccf5facc7d21"
      ...
    }

  # aws_security_group.web이 생성됩니다
  + resource "aws_security_group" "web" {
      + name = "ccaws-tf01-web-sg"
      ...
    }
```

해석:
문법 검사가 통과되었고, EC2 인스턴스 1개와 Security Group 1개가 생성될 예정이다. EC2는 `subnet-063f9ccf5facc7d21` (us-east-1f)에 배치된다. `plan`은 실제 AWS 리소스를 변경하지 않으며 변경 예정 내용만 출력한다.

---

## 배포 및 확인

```bash
# EC2 인스턴스와 관련 리소스를 생성합니다.
terraform apply

# 배포 완료 후 정의된 모든 output 값을 읽습니다.
terraform output

# 셸 명령어에서 사용할 수 있도록 퍼블릭 IP만 따옴표 없이 출력합니다.
terraform output -raw instance_public_ip

# 인스턴스로 HTTP 요청을 직접 전송합니다.
curl "http://$(terraform output -raw instance_public_ip)"
```

실제 출력:
```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:
instance_id         = "i-07cd32398b0e3aa26"
instance_public_dns = "ec2-100-24-117-227.compute-1.amazonaws.com"
instance_public_ip  = "100.24.117.227"
security_group_id   = "sg-0f23ef5cb6fb22ffc"
selected_subnet_id  = "subnet-063f9ccf5facc7d21"

100.24.117.227

<h1>Terraform Example 01</h1>
<p>Role: Single EC2 web server</p>
<p>Name Prefix: ccaws-tf01</p>
<p>Instance ID: </p>
<p>Availability Zone: </p>
```

해석:
EC2 인스턴스(`i-07cd32398b0e3aa26`)와 Security Group(`sg-0f23ef5cb6fb22ffc`)이 성공적으로 생성되었다. 퍼블릭 IP `100.24.117.227`으로 HTTP 요청 시 Nginx가 정상 응답한다. Instance ID와 Availability Zone이 비어있는 것은 `user-data.sh`가 IMDSv1 방식으로 메타데이터를 요청하지만 Amazon Linux 2023은 기본적으로 IMDSv2만 허용하기 때문이다. AWS CLI로 실제 AZ를 확인한 결과 `us-east-1f`임을 확인했다.

---

## 리소스 삭제

```bash
# 이 예제에서 생성한 모든 리소스를 삭제합니다.
terraform destroy
```

실제 출력:
```
aws_instance.web: Destroying... [id=i-07cd32398b0e3aa26]
aws_instance.web: Destruction complete after 30s
aws_security_group.web: Destroying... [id=sg-0f23ef5cb6fb22ffc]
aws_security_group.web: Destruction complete after 1s

Destroy complete! Resources: 2 destroyed.
```

해석:
EC2 인스턴스가 먼저 삭제(30초 소요)된 후 Security Group이 삭제되었다. Terraform이 의존 관계를 파악하여 올바른 순서로 삭제한다. EC2가 완전히 종료되기 전에는 Security Group을 삭제할 수 없기 때문이다.

---

## 크리덴셜 취급 주의사항

```text
AWS Academy 임시 크리덴셜은 환경 변수에만 저장하세요.
AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN을 terraform.tfvars에 저장하지 마세요.
```
