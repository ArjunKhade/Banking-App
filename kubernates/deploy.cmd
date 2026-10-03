@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=apply"

if /I "%ACTION%"=="apply" goto :do_apply
if /I "%ACTION%"=="delete" goto :do_delete
if /I "%ACTION%"=="status" goto :do_status

echo Usage:
echo   deploy.cmd         (applies all manifests)
echo   deploy.cmd apply   (applies all manifests)
echo   deploy.cmd delete  (deletes all deployed manifests)
echo   deploy.cmd status  (shows pod and service status)
exit /b 1

:do_apply
echo ======================================================
echo Deploying Kubernetes Manifests...
echo ======================================================

echo [1/6] Applying ConfigMap...
kubectl apply -f "%SCRIPT_DIR%2_configmaps.yaml"
if errorlevel 1 goto :fail

echo [2/6] Applying Discovery Server...
kubectl apply -f "%SCRIPT_DIR%kubernetes-discoveryserver.yml"
if errorlevel 1 goto :fail

echo [3/6] Applying Keycloak, Config Server, and Kafka...
kubectl apply -f "%SCRIPT_DIR%1_keycloak.yml" -f "%SCRIPT_DIR%3_configserver.yml" -f "%SCRIPT_DIR%9_kafka.yml"
if errorlevel 1 goto :fail

echo [4/6] Applying Microservices (accounts, loans, cards)...
kubectl apply -f "%SCRIPT_DIR%5_accounts.yml" -f "%SCRIPT_DIR%6_loans.yml" -f "%SCRIPT_DIR%7_cards.yml"
if errorlevel 1 goto :fail

echo [5/6] Applying Gateway Server and Message Service...
kubectl apply -f "%SCRIPT_DIR%8_gateway.yml" -f "%SCRIPT_DIR%10_message.yml"
if errorlevel 1 goto :fail

echo [6/6] All manifests applied successfully!
echo.
kubectl get pods
exit /b 0

:do_delete
echo ======================================================
echo Deleting Kubernetes Resources...
echo ======================================================

echo Deleting Microservices...
kubectl delete -f "%SCRIPT_DIR%8_gateway.yml" -f "%SCRIPT_DIR%10_message.yml" -f "%SCRIPT_DIR%5_accounts.yml" -f "%SCRIPT_DIR%6_loans.yml" -f "%SCRIPT_DIR%7_cards.yml" --ignore-not-found=true

echo Deleting Keycloak, Config Server, and Kafka...
kubectl delete -f "%SCRIPT_DIR%1_keycloak.yml" -f "%SCRIPT_DIR%3_configserver.yml" -f "%SCRIPT_DIR%9_kafka.yml" --ignore-not-found=true

echo Deleting Discovery Server and ConfigMap...
kubectl delete -f "%SCRIPT_DIR%kubernetes-discoveryserver.yml" -f "%SCRIPT_DIR%2_configmaps.yaml" --ignore-not-found=true

echo.
echo All resources deleted!
exit /b 0

:do_status
echo ======================================================
echo Kubernetes Pods:
echo ======================================================
kubectl get pods
echo.
echo ======================================================
echo Kubernetes Services:
echo ======================================================
kubectl get svc
exit /b 0

:fail
echo.
echo [ERROR] Deployment failed!
exit /b 1
