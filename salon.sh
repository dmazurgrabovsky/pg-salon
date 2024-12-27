#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"

MAIN_MENU() {

  if [[ $1 ]]
  then
    echo -e "\n$1"
  else
    echo -e "\nWelcome to My Salon, how can I help you?\n"  
  fi

  #get available bikes 
  AVAILABLE_SERVICES=$($PSQL "SELECT service_id, name from services ORDER BY service_id" )

  #if no services available 
  if [[ -z $AVAILABLE_SERVICES ]]
  then
    #send to main menu
    MAIN_MENU "Sorry, we don't have any services right now."
  else
    #display available services
    echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
    do
      echo "$SERVICE_ID) $SERVICE_NAME"
    done
  fi

  read SERVICE_ID_SELECTED
  #if input is not a number
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]     
  then
    # send to main menu
    MAIN_MENU "I could not find that service. What would you like today?"
  else
    #get service id from db
    SERVICE_DB_READ_RESULT=$($PSQL "SELECT service_id, name FROM services WHERE service_id=$SERVICE_ID_SELECTED" )

    #if input does not correspond to service
    if [[ -z $SERVICE_DB_READ_RESULT ]]
    then
      MAIN_MENU "I could not find that service. What would you like today?"
    else
      #service is valid, let us parse it
      read SERVICE_ID BAR SERVICE_NAME < <(echo "$SERVICE_DB_READ_RESULT" ) 

      #handle customer
      #get customer info
      echo -e "\nWhat's your phone number?"
      read CUSTOMER_PHONE
      CUSTOMER_NAME=$($PSQL "select name from customers where phone='$CUSTOMER_PHONE'" | sed 's/ *//')
      #if customer doesn't exist
      if [[ -z $CUSTOMER_NAME ]]
      then
        # get new customer name
        echo -e "\nI don't have a record for that phone number, what's your name?"
        read CUSTOMER_NAME

        # insert new customer
        INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
      fi

      # get customer_id
      CUSTOMER_ID=$($PSQL "select customer_id from customers where phone='$CUSTOMER_PHONE'" | sed -E 's/^ *//g' )

      #ask for time
      echo -e "\nWhat time would you like your cut, $CUSTOMER_NAME? "
      read SERVICE_TIME

      #register appointment
      APPT_REG_RESULT=$($PSQL "insert into appointments(customer_id, service_id, time) values ($CUSTOMER_ID, $SERVICE_ID, '$SERVICE_TIME' )" )
      echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
    fi

  fi
}

MAIN_MENU
