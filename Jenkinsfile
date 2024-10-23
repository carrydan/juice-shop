pipeline {
    agent any

    environment {
        ANSIBLE_CONFIG = 'juice-shop/ansible-k8s/ansible.cfg'  // ��������� ���������� ���� ������������ Ansible
        KUBECONFIG = "${WORKSPACE}/.kube/config"  // ���������� kubeconfig ��� ����������� � ��������
    }

    stages {
        stage('Clone Repository') {
            steps {
                script {
                    // ��������� ����������� � ������ master
                    git branch: 'master', url: 'https://github.com/carrydan/juice-shop.git'
                }
            }
        }

        // ���� ��������� Ansible � ������������ ���������������, ��� ��� �� ��� ���������
        /*
        stage('Install Ansible and Dependencies') {
            steps {
                script {
                    // ������������� Ansible � ����������� �����������
                    sh '''
                    pip install ansible kubernetes
                    '''
                }
            }
        }
        */

        stage('Install Monitoring Stack') {
            steps {
                script {
                    // ������������� Prometheus � Grafana
                    sh '''
                    ansible-playbook -i juice-shop/ansible-k8s/inventory juice-shop/ansible-k8s/install_monitoring.yml -e ansible_python_interpreter=/home/carrydan/venv/bin/python3
                    '''
                }
            }
        }

        stage('Install Logging Stack') {
            steps {
                script {
                    // ������������� Elasticsearch, Fluentd � Kibana
                    sh '''
                    ansible-playbook -i juice-shop/ansible-k8s/inventory juice-shop/ansible-k8s/install_logging.yml -e ansible_python_interpreter=/home/carrydan/venv/bin/python3
                    '''
                }
            }
        }

        stage('Deploy OWASP Juice Shop') {
            steps {
                script {
                    // ������ ���������� Juice Shop � �������������� Helm
                    sh '''
                    ansible-playbook -i juice-shop/ansible-k8s/inventory juice-shop/ansible-k8s/deploy_application.yml -e ansible_python_interpreter=/home/carrydan/venv/bin/python3
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    // ������ ������ ��� ���������� Juice Shop
                    dir('juice-shop') {
                        sh '''
                        npm test     // ������ ������
                        '''
                    }
                }
            }
        }

        stage('Show Access Information') {
            steps {
                script {
                    // ������� ������ ��� ������� � Grafana, Prometheus, Kibana, Elasticsearch � ���������� Juice Shop
                    echo "Grafana �������� �� ������: http://<your-host>:32000"
                    echo "Prometheus �������� �� ������: http://<your-host>:9090"
                    echo "Kibana �������� �� ������: http://<your-host>:5601"
                    echo "Elasticsearch �������� �� ������: http://<your-host>:9200"
                    echo "OWASP Juice Shop �������� �� ������: http://<your-host>:<application-port>"

                    // ������� ��� ��������� ������� ������ Grafana
                    echo "��� ����� � Grafana �����������: ����� - admin, ������ - admin (���� �� ������)"
                    
                    // ������� ������ ��� ������� � Kibana (���� ����)
                    echo "��� ����� � Kibana, ����������� ����������� ������� ������ (���� ���������): ����� - elastic, ������ - <������_Elasticsearch>"
                }
            }
        }
    }

    post {
        success {
            script {
                // ��������� �� �������� ���������� ���������
                echo '�������� ������� ��������!'
            }
        }
        failure {
            script {
                // ��������� � ������� ���������
                echo '�������� �������� � �������.'
            }
        }
    }
}
