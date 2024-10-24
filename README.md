Вот обновленный полный файл README на русском языке, который включает информацию, соответствующую вашему обновленному Jenkins pipeline:

```markdown
# Juice Shop - Автоматизированное Развертывание с Ansible, Kubernetes и Jenkins

## Описание

Этот проект предназначен для автоматизированного развертывания приложения [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) с использованием **Ansible**, **Kubernetes** (Minikube), и пайплайна в **Jenkins**. Пайплайн автоматизирует процесс клонирования репозитория, установки стеков мониторинга и логирования, а также развертывание приложения OWASP Juice Shop в Minikube. После развертывания открывается публичный URL через **Ngrok**.

## Предварительные требования

Перед началом убедитесь, что у вас установлены следующие зависимости:

- **Jenkins** — для автоматизации пайплайнов.
- **Ansible** — для автоматизации процесса развертывания.
- **Minikube** — для локального развертывания Kubernetes кластера.
- **Kubectl** — для взаимодействия с Minikube.
- **Ngrok** — для создания публичного туннеля к локальному Minikube.
- **Docker** — для работы с контейнерами и Minikube.

## Установка

### Шаг 1: Установка Jenkins

1. Установите Jenkins на виртуальную машину, следуя [официальной инструкции](https://www.jenkins.io/doc/book/installing/).
2. Убедитесь, что Jenkins запущен и доступен через веб-интерфейс.

### Шаг 2: Установка Minikube и Kubectl

1. Установите Minikube, следуя [документации](https://minikube.sigs.k8s.io/docs/start/).
2. Запустите Minikube:

   ```bash
   minikube start --driver=docker
   ```

3. Убедитесь, что Minikube работает:

   ```bash
   minikube status
   ```

4. Убедитесь, что **kubectl** установлен и настроен для работы с Minikube:

   ```bash
   kubectl get nodes
   ```

### Шаг 3: Настройка Ansible

1. Установите Ansible на машину с Jenkins, используя пакетный менеджер:

   ```bash
   sudo apt-get update
   sudo apt-get install -y ansible
   ```

2. Клонируйте этот репозиторий на сервер Jenkins:

   ```bash
   git clone https://github.com/carrydan/juice-shop.git
   ```

3. Настройте Ansible, убедитесь, что у вас есть корректный файл инвентаря. Пример инвентаря:

   ```ini
   [kubernetes]
   127.0.0.1 ansible_connection=local
   ```

### Шаг 4: Настройка Ngrok

1. Установите **Ngrok** и получите токен авторизации.
2. Вставьте токен авторизации в **Jenkins Credentials** под именем `ngrok_authtoken`.

## Использование

### Запуск пайплайна Jenkins

1. Откройте веб-интерфейс Jenkins и создайте новый пайплайн проект.
2. В конфигурации проекта вставьте следующий Jenkinsfile, который автоматизирует развертывание приложения и стеков мониторинга и логирования:

```groovy
pipeline {
    agent any

    environment {
        KUBECONFIG = '/home/carrydan/.kube/config'
        vault_jwt_secret = credentials('jwt')
        NGROK_AUTHTOKEN = credentials('ngrok_authtoken')
    }

    stages {
        stage('Clone Repository') {
            steps {
                script {
                    git branch: 'master', url: 'https://github.com/carrydan/juice-shop.git'
                }
            }
        }

        stage('Clean Up Old Pods') {
            steps {
                script {
                    echo 'Deleting old Pods in monitoring, logging, and juice-shop namespaces...'
                    sh '''
                    kubectl delete pods --all -n monitoring || true
                    kubectl delete pods --all -n logging || true
                    kubectl delete pods --all -n juice-shop-namespace || true
                    '''
                }
            }
        }

        stage('Cache Docker Images') {
            steps {
                script {
                    sh '''
                    echo "Caching Docker images..."
                    minikube image load quay.io/prometheus/prometheus:v2.54.1
                    minikube image load grafana/grafana:11.2.2-security-01
                    minikube image load docker.elastic.co/elasticsearch/elasticsearch:8.5.1
                    minikube image load docker.elastic.co/kibana/kibana:8.5.1
                    '''
                }
            }
        }

        stage('Install Monitoring Stack') {
            steps {
                script {
                    sh '''
                    ansible-playbook -vvv -i /home/carrydan/juice-shop/ansible-k8s/inventory /home/carrydan/juice-shop/ansible-k8s/install_monitoring.yml -e ansible_python_interpreter=/home/carrydan/venv/bin/python3
                    '''
                }
            }
        }

        stage('Wait for Monitoring Stack to be Ready') {
            steps {
                script {
                    sh '''
                    kubectl wait --namespace monitoring --for=condition=ready pod -l app.kubernetes.io/name=prometheus --timeout=300s
                    kubectl wait --namespace monitoring --for=condition=ready pod -l app.kubernetes.io/name=grafana --timeout=300s
                    '''
                }
            }
        }

        stage('Install Logging Stack') {
            steps {
                script {
                    sh '''
                    ansible-playbook -vvv -i /home/carrydan/juice-shop/ansible-k8s/inventory /home/carrydan/juice-shop/ansible-k8s/install_logging.yml -e ansible_python_interpreter=/home/carrydan/venv/bin/python3
                    '''
                }
            }
        }

        stage('Wait for Logging Stack to be Ready') {
            steps {
                script {
                    sh '''
                    kubectl wait --namespace logging --for=condition=ready pod -l app=elasticsearch-master --timeout=300s
                    kubectl wait --namespace logging --for=condition=ready pod -l app=kibana --timeout=300s
                    '''
                }
            }
        }

        stage('Deploy OWASP Juice Shop') {
            steps {
                script {
                    sh '''
                    ansible-playbook -vvv -i /home/carrydan/juice-shop/ansible-k8s/inventory /home/carrydan/juice-shop/ansible-k8s/deploy_application.yml \
                    -e ansible_python_interpreter=/home/carrydan/venv/bin/python3 -e vault_jwt_secret=${vault_jwt_secret}
                    '''
                }
            }
        }

        stage('Start Ngrok Tunnel') {
            steps {
                script {
                    def nodeIp = sh(returnStdout: true, script: "minikube ip").trim()

                    sh '''
                    echo "Setting up Ngrok..."
                    ngrok authtoken ${NGROK_AUTHTOKEN}
                    ngrok http ${nodeIp}:30000 --log=stdout > ngrok.log &
                    sleep 5
                    '''

                    def publicUrl = sh(returnStdout: true, script: "curl --silent http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url'").trim()

                    echo "Access OWASP Juice Shop at: ${publicUrl}"
                }
            }
        }

        stage('Check Service Availability') {
            steps {
                script {
                    def nodeIp = sh(returnStdout: true, script: "minikube ip").trim()

                    def services = [
                        ['name': 'Grafana', 'url': "http://${nodeIp}:32000"],
                        ['name': 'Prometheus', 'url': "http://${nodeIp}:30900"],
                        ['name': 'Kibana', 'url': "http://${nodeIp}:32001"],
                        ['name': 'Elasticsearch', 'url': "http://${nodeIp}:32002"],
                        ['name': 'OWASP Juice Shop', 'url': "http://${nodeIp}:30000"]
                    ]

                    for (service in services) {
                        echo "Checking ${service.name} availability..."
                        sh "curl --fail --connect-timeout 5 ${service.url} || echo '${service.name} is not available'"
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                echo 'Пайплайн успешно завершён!'
            }
        }
        failure {
            script {
                echo 'Пайплайн завершён с ошибкой.'
            }
        }
    }
}
```

3. Запустите пайплайн, и Jenkins выполнит автоматизированное развертывание приложения в Minikube.

## Структура проекта

- **ansible-k8s/**: содержит Ansible плейбуки для автоматизированного развертывания.
- **kubernetes/**: содержит Kubernetes манифесты для развертывания приложения.

## Решение проблем

### Ошибки Image Pull Backoff

Если возникают ошибки при загрузке Docker образов, убедитесь, что образы доступны и правильно настроены в Kubernetes манифестах.

### Проверка логов

Для проверки логов приложения используйте команду:

```bash
kubectl logs -l app=juice

-shop -n juice-shop-namespace
```

## Контрибьюторы

Если у вас есть предложения по улучшению проекта, открывайте Pull Request или создавайте Issue.

## Лицензия

Этот проект лицензируется на условиях лицензии MIT. Подробности можно найти в файле LICENSE