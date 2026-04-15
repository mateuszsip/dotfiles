def helm-login [] { aws ecr get-login-password --region eu-west-1 --profile uk-plat-prod:len_ecr_reader | helm registry login --username AWS --password-stdin 117771453557.dkr.ecr.eu-west-1.amazonaws.com }

def helm-render [environment] { helm template --values ../values-$"($environment)"-shared.yaml --values values.yaml --values values-$"($environment)".yaml . }

