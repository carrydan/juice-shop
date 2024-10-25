pipeline {
    agent any

    environment {
        DOCKER_HUB_REPO = 'carrydan/juice-shop'
        KUBECONFIG = '/home/carrydan/.kube/config'
        vault_jwt_secret = credentials('jwt')
        NGROK_AUTHTOKEN = credentials('ngrok_authtoken')
    }

    stages {
        // Закомментированы стадии, которые уже были выполнены
        /*
        stage('Cleanup') {
            steps {
                script {
                    echo "Cleaning up old resources..."
                    sh '''
                    helm uninstall juice-shop --namespace juice-shop || true
                    kubectl delete namespace juice-shop || true
                    kubectl delete pods --all -n monitoring || true
                    kubectl delete pods --all -n logging || true
                    '''
                }
            }
        }

        stage('Clone Repository') {
            steps {
                git branch: 'master', url: 'https://github.com/carrydan/juice-shop.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_HUB_REPO}:latest")
                }
            }
        }
        

        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'docker') {
                        docker.image("${DOCKER_HUB_REPO}:latest").push()
                    }
                }
            }
        }
        */
        
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

        stage('Install Monitoring and Logging Stack') {
            steps {
                script {
                    sh 'ansible-playbook -i /home/carrydan/juice-shop/ansible-k8s/inventory /home/carrydan/juice-shop/ansible-k8s/install_monitoring.yml'
                    sh 'ansible-playbook -i /home/carrydan/juice-shop/ansible-k8s/inventory /home/carrydan/juice-shop/ansible-k8s/install_logging.yml'
                }
            }
        }

        stage('Wait for Monitoring and Logging Stack') {
            steps {
                script {
                    sh '''
                    kubectl wait --namespace monitoring --for=condition=ready pod -l app.kubernetes.io/name=prometheus --timeout=300s
                    kubectl wait --namespace monitoring --for=condition=ready pod -l app.kubernetes.io/name=grafana --timeout=300s
                    kubectl wait --namespace logging --for=condition=ready pod -l app=elasticsearch-master --timeout=300s
                    kubectl wait --namespace logging --for=condition=ready pod -l app=kibana --timeout=300s
                    '''
                }
            }
        }

        stage('Deploy OWASP Juice Shop using Helm') {
            steps {
                script {
                    sh '''
                    helm upgrade --install juice-shop /home/carrydan/juice-shop/helm-charts/juice-shop \
                        --set image.repository=${DOCKER_HUB_REPO} \
                        --set image.tag=latest \
                        --namespace juice-shop --create-namespace
                    '''
                }
            }
        }

        stage('Start Ngrok Tunnel') {
            steps {
                script {
                    def nodeIp = sh(returnStdout: true, script: "minikube ip").trim()
                    sh '''
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
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
