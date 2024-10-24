# OWASP Juice Shop на Kubernetes с использованием Jenkins и Ansible

## Описание проекта

OWASP Juice Shop — это современное веб-приложение, намеренно содержащее уязвимости для обучения безопасности. Этот проект развертывается в Kubernetes с использованием CI/CD пайплайна на Jenkins и автоматизированного развёртывания через Ansible.

## Требования

Для успешного развертывания проекта вам понадобятся следующие инструменты:

- Kubernetes (использование Minikube)
- Jenkins (установленный и настроенный на отдельной машине или в кластере)
- Ansible (для выполнения плейбуков)
- Docker (для работы с контейнерами и образами)

## Установка

### Шаги развертывания через Jenkins:

1. **Клонирование репозитория:**

    В пайплайне Jenkins используется этап клонирования репозитория:
    
    ```bash
    git clone https://github.com/carrydan/juice-shop.git
    ```

2. **Очистка старых pod'ов:**

    Пайплайн автоматически удаляет старые pod'ы в неймспейсах `monitoring`, `logging` и `juice-shop-namespace` перед установкой нового стека:

    ```bash
    kubectl delete pods --all -n monitoring || true
    kubectl delete pods --all -n logging || true
    kubectl delete pods --all -n juice-shop-namespace || true
    ```

3. **Кеширование Docker образов:**

    Для ускорения развёртывания пайплайн загружает необходимые Docker-образы:

    ```bash
    minikube image load quay.io/prometheus/prometheus:v2.54.1
    minikube image load grafana/grafana:11.2.2-security-01
    minikube image load docker.elastic.co/elasticsearch/elasticsearch:8.5.1
    minikube image load docker.elastic.co/kibana/kibana:8.5.1
    ```

4. **Установка стека мониторинга и логирования:**

    Автоматическая установка через Ansible:

    ```bash
    ansible-playbook -i inventory install_monitoring.yml
    ansible-playbook -i inventory install_logging.yml
    ```

5. **Развёртывание OWASP Juice Shop:**

    Пайплайн разворачивает Juice Shop через Ansible, используя Minikube:

    ```bash
    ansible-playbook -i inventory deploy_application.yml -e vault_jwt_secret=${vault_jwt_secret}
    ```

6. **Настройка туннеля через Ngrok:**

    Для доступа к приложению извне создается туннель с помощью Ngrok:

    ```bash
    ngrok authtoken ${NGROK_AUTHTOKEN}
    ngrok http $(minikube ip):30000 --log=stdout > ngrok.log &
    ```

7. **Проверка доступности сервисов:**

    Скрипт проверяет, доступны ли развернутые сервисы (Grafana, Prometheus, Kibana и сам Juice Shop):

    ```bash
    curl --fail --connect-timeout 5 http://$(minikube ip):32000 || echo 'Grafana is not available'
    ```

## Лицензия

Проект распространяется под лицензией MIT. Полный текст лицензии доступен в файле [LICENSE](./LICENSE).

## Вклад

Мы приветствуем ваш вклад в развитие проекта. Пожалуйста, ознакомьтесь с [CONTRIBUTING.md](./CONTRIBUTING.md) для получения информации о том, как начать.

## Поддержка

Для вопросов и помощи используйте [чат Gitter](https://gitter.im/juice-shop) или обратитесь к документации проекта.
