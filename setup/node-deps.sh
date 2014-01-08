#!/usr/bin/env bash

cd /usr/local/src/CartoDB-SQL-API
git checkout master
./configure
npm install

cd /usr/local/src/Windshaft-cartodb
git checkout master
./configure --with-mapnik-version='2.1.1'
./configure --with-mapnik-version='2.1.1' --environment='production'
npm install
