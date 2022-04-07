#! /usr/bin/env bash

RED="31"
GREEN="32"
BOLDGREEN="\e[1;${GREEN}m"
ITALICRED="\e[3;${RED}m"
ENDCOLOR="\e[0m"


echo -e  "${ITALICRED}---->  installing Some Extra Packages ...${ENDCOLOR}"
sh ./extra.sh
echo -e  "${BOLDGREEN}----> Extra Packages  Installed SUCCESSFULLY.${ENDCOLOR}"


echo -e  "${ITALICRED}---->  installing git...${ENDCOLOR}"

# sh ./git.sh
echo -e  "${BOLDGREEN}----> git Installed SUCCESSFULLY.${ENDCOLOR}"




echo -e  "${ITALICRED}---->  installing Node v14.8.0...${ENDCOLOR}"

# sh ./nvm_node.sh
echo -e  "${BOLDGREEN}----> NVM and Node v14.8.0 Installed SUCCESSFULLY.${ENDCOLOR}"




echo -e  "${ITALICRED}---->  installing Angular v11.2.15...${ENDCOLOR}"

#sh ./angular.sh
echo -e  "${BOLDGREEN}----> Angular v11.2.15 Installed SUCCESSFULLY.${ENDCOLOR}"




echo -e  "${ITALICRED}----> installing ELK STACK...${ENDCOLOR}"

# sh ./elk.sh

echo -e  "${BOLDGREEN}----> ELK STACK INSTALLED SUCCESSFULLY.${ENDCOLOR}"


echo -e  "${ITALICRED}---->  installing Node v14.8.0...${ENDCOLOR}"

# sh ./nvm_node.sh
echo -e  "${BOLDGREEN}----> NVM and Node v14.8.0 Installed SUCCESSFULLY.${ENDCOLOR}"



echo -e  "${ITALICRED}---->  installing Redis...${ENDCOLOR}"

#sh ./redis.sh

echo -e  "${BOLDGREEN}----> redis Installed SUCCESSFULLY.${ENDCOLOR}"


echo -e  "${ITALICRED}---->  installing postgresql...${ENDCOLOR}"

#sh ./postgres.sh

echo -e  "${BOLDGREEN}----> postgresql Installed SUCCESSFULLY.${ENDCOLOR}"