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

                    // Получение публичного URL из Ngrok
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
