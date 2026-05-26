# Аудит безопасности контейнеров

## Состав решения

`audit-zone` создаётся с PodSecurity Admission в режиме `restricted` (`enforce`, `audit`, `warn`). Три manifest в `insecure-manifests/` демонстрируют `privileged`, `hostPath` и запуск от UID 0; серверная валидация должна отклонить их. Исправленные pod в `secure-manifests/` запускаются non-root, запрещают privilege escalation, удаляют Linux capabilities, используют `RuntimeDefault` seccomp и read-only root filesystem.

Gatekeeper дублирует ключевые ограничения для аудита и защиты namespace без PSA: запрещает `privileged`, запрещает `hostPath`, требует `runAsNonRoot: true` и `readOnlyRootFilesystem: true`. Последние два требования объединены в template `runasnonroot.yaml`, чтобы сохранить заданную структуру из трёх templates.

`audit-policy.yaml` исправляет предложенный в задании пример: ресурсы `roles` и `rolebindings` относятся к API group `rbac.authorization.k8s.io`, а не к core group.

## Проверка PodSecurity Admission

```bash
kubectl apply -f 01-create-namespace.yaml
bash verify/verify-admission.sh
```

Скрипт успешно завершается, если все небезопасные pod отклонены, а все исправленные manifest проходят server-side validation.

## Проверка Gatekeeper

До проверки Gatekeeper должен быть установлен в кластер, например через его Helm chart:

```bash
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm repo update
helm install gatekeeper gatekeeper/gatekeeper --namespace gatekeeper-system --create-namespace
bash verify/validate-security.sh
```

Скрипт применяет templates и constraints, проверяет PSA, затем повторяет негативные проверки в namespace `gatekeeper-validation` без меток PSA. Благодаря этому отклонение во второй части подтверждает именно применение правил Gatekeeper, включая обязательный read-only root filesystem.

## Ожидаемый результат

| Manifest / проверка | PSA `audit-zone` | Gatekeeper `gatekeeper-validation` |
| --- | --- | --- |
| `01-privileged-pod.yaml` | Отклонён | Отклонён |
| `02-hostpath-pod.yaml` | Отклонён | Отклонён |
| `03-root-user-pod.yaml` | Отклонён | Отклонён |
| Pod с `readOnlyRootFilesystem: false` | PSA не является доказательством данного требования | Отклонён |
| `secure-manifests/*.yaml` | Допущены | Соответствуют constraints |
