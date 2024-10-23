pipeline {
    agent any

    environment {
        ANSIBLE_CONFIG = 'juice-shop/ansible-k8s/ansible.cfg'  // Указываем корректный файл конфигурации Ansible
        KUBECONFIG = "${WORKSPACE}/.kube/config"  // Используем kubeconfig для подключения к кластеру
    }

    stages {
        stage('Clone Repository') {
            steps {
                script {
                    // Клонируем репозиторий с веткой master
                    git branch: 'master', url: 'https://github.com/carrydan/juice-shop.git'
                }
            }
        }

        // Этап установки Ansible и зависимостей закомментирован, так как всё уже настроено
        /*
        stage('Install Ansible and Dependencies') {
            steps {
                script {
                    // Устанавливаем Ansible и необходимые зависимости
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
                    // Устанавливаем Prometheus и Grafana
                    sh '''
                    ansible-playbook -i juice-shop/ansible-k8s/inventory juice-shop/ansible-k8s/install_monitoring.yml -e ansible_python_interpreter=/home/carrydan/venv/bin/python3
                    '''
                }
            }
        }

        stage('Install Logging Stack') {
            steps {
                script {
                    // Устанавливаем Elasticsearch, Fluentd и Kibana
                    sh '''
                    ansible-playbook -i juice-shop/ansible-k8s/inventory juice-shop/ansible-k8s/install_logging.yml -e ansible_python_interpreter=/home/carrydan/venv/bin/python3
                    '''
                }
            }
        }

        stage('Deploy OWASP Juice Shop') {
            steps {
                script {
                    // Деплой приложения Juice Shop с использованием Helm
                    sh '''
                    ansible-playbook -i juice-shop/ansible-k8s/inventory juice-shop/ansible-k8s/deploy_application.yml -e ansible_python_interpreter=/home/carrydan/venv/bin/python3
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    // Запуск тестов для приложения Juice Shop
                    dir('juice-shop') {
                        sh '''
                        npm test     // Запуск тестов
                        '''
                    }
                }
            }
        }

        stage('Show Access Information') {
            steps {
                script {
                    // Выводим адреса для доступа к Grafana, Prometheus, Kibana, Elasticsearch и приложению Juice Shop
                    echo "Grafana доступна по адресу: http://<your-host>:32000"
                    echo "Prometheus доступен по адресу: http://<your-host>:9090"
                    echo "Kibana доступна по адресу: http://<your-host>:5601"
                    echo "Elasticsearch доступен по адресу: http://<your-host>:9200"
                    echo "OWASP Juice Shop доступен по адресу: http://<your-host>:<application-port>"

                    // Команда для получения учетных данных Grafana
                    echo "Для входа в Grafana используйте: логин - admin, пароль - admin (если не изменён)"
                    
                    // Учетные данные для доступа к Kibana (если есть)
                    echo "Для входа в Kibana, используйте стандартные учетные данные (если настроено): логин - elastic, пароль - <пароль_Elasticsearch>"
                }
            }
        }
    }

    post {
        success {
            script {
                // Сообщение об успешном выполнении пайплайна
                echo 'Пайплайн успешно завершён!'
            }
        }
        failure {
            script {
                // Сообщение о неудаче пайплайна
                echo 'Пайплайн завершён с ошибкой.'
            }
        }
    }
}
