#!/bin/bash

APP_DATA=../storage

mkdir -p $APP_DATA/grafana
mkdir -p $APP_DATA/jenkins_home

mkdir -p $APP_DATA/garage/meta/
mkdir -p $APP_DATA/garage/data/

mkdir -p $APP_DATA/jenkins_home

mkdir -p $APP_DATA/gitlab_home/config
mkdir -p $APP_DATA/gitlab_home/logs
mkdir -p $APP_DATA/gitlab_home/data

mkdir -p $APP_DATA/redmine-postgresql-db

mkdir -p $APP_DATA/redmine-data
mkdir -p $APP_DATA/redmine-logs

# TODO() Less rights
chmod 0777 $APP_DATA -R
