# Ролевая модель доступа к Kubernetes

## Принципы

Кластер разделяется по бизнес-доменам через namespace `sales`, `tenant-services`, `finance` и `data`. Права назначаются группам, полученным из корпоративной идентификации; пользовательские сертификаты в скрипте имитируют эту интеграцию для Minikube. Чтение `Secret` является привилегированной операцией и выдаётся только группе ИБ для расследования в контролируемом окне доступа. Разработчики и операционные менеджеры секреты не читают.

| Роль Kubernetes | Группа / примеры пользователей | Область | Разрешения | Явные ограничения и назначение |
| --- | --- | --- | --- | --- |
| `pd-cluster-viewer` | `pd:operations-viewers` / `operations-viewer` | Весь кластер | `get`, `list`, `watch` workloads, services, events, network policies, RBAC metadata | Нет доступа к `secrets`, изменению объектов и `exec`; используется операционными менеджерами для просмотра состояния продуктов. |
| `pd-domain-deployer` | `pd:sales-developers` / `sales-developer`; `pd:tenant-developers` / `tenant-developer` | Только соответствующий namespace через `RoleBinding` | Развёртывание workloads, service/configmap, просмотр pod/log/event, настройка network policy | Нет `secrets`, RBAC, namespace и чужих доменов; поддерживает команды продаж и ЖКУ. |
| `pd-platform-operator` | `pd:platform-operators` / `platform-operator` | Весь кластер | Настройка namespaces, quotas, workloads, services, ingress/network policies, jobs, storage claims | Нет `secrets` и RBAC; DevOps/эксплуатация может настраивать платформу, но не выдавать себе полномочия. |
| `pd-security-auditor` | `pd:security-auditors` / `security-auditor` | Весь кластер | Просмотр конфигурации, RBAC и network policies; `get/list/watch` secrets для расследований | Привилегированный доступ должен активироваться заявкой, журналироваться и регулярно пересматриваться; нет изменений ресурсов или `exec`. |
| `cluster-admin` (встроенная) | `pd:platform-admins` / `platform-admin` | Весь кластер | Полное администрирование, включая RBAC и аварийное восстановление | Break-glass роль, не используется для ежедневных развёртываний; требует MFA/учёта выдачи вне Minikube. |

## Пользователи демонстрационного кластера

| Пользователь | Группа в сертификате | Привязка |
| --- | --- | --- |
| `operations-viewer` | `pd:operations-viewers` | `pd-cluster-viewer` |
| `sales-developer` | `pd:sales-developers` | `pd-domain-deployer` в `sales` |
| `tenant-developer` | `pd:tenant-developers` | `pd-domain-deployer` в `tenant-services` |
| `platform-operator` | `pd:platform-operators` | `pd-platform-operator` |
| `security-auditor` | `pd:security-auditors` | `pd-security-auditor` |
| `platform-admin` | `pd:platform-admins` | встроенная `cluster-admin` как аварийная роль |

## Применение и проверка

```bash
minikube start
bash 01-create-users.sh
bash 02-create-roles.sh
bash 03-bind-users.sh

kubectl auth can-i list pods --as=operations-viewer --as-group=pd:operations-viewers
kubectl auth can-i get secrets --as=operations-viewer --as-group=pd:operations-viewers
kubectl auth can-i patch deployment -n sales --as=sales-developer --as-group=pd:sales-developers
kubectl auth can-i patch deployment -n tenant-services --as=sales-developer --as-group=pd:sales-developers
kubectl auth can-i get secrets --as=security-auditor --as-group=pd:security-auditors
kubectl auth can-i create clusterrolebinding --as=platform-operator --as-group=pd:platform-operators
```

Ожидается, что второй, четвёртый и последний запросы вернут `no`, а остальные проверки соответствующих полномочий вернут `yes`.
