# CyberSource::AgentCapabilitiesApi

All URIs are relative to *https://apitest.cybersource.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**cancel_purchase_intent**](AgentCapabilitiesApi.md#cancel_purchase_intent) | **PUT** /icc/v1/instructions/{instructionId}/cancel | Cancel a purchase intent
[**confirm_transaction_events**](AgentCapabilitiesApi.md#confirm_transaction_events) | **POST** /icc/v1/instructions/{instructionId}/confirmations | Confirm transaction events
[**enroll_card**](AgentCapabilitiesApi.md#enroll_card) | **POST** /icc/v1/tokens | Enroll a card
[**initiate_purchase_intent**](AgentCapabilitiesApi.md#initiate_purchase_intent) | **POST** /icc/v1/instructions | Initiate a purchase intent
[**retrieve_payment_credentials**](AgentCapabilitiesApi.md#retrieve_payment_credentials) | **POST** /icc/v1/instructions/{instructionId}/credentials | Retrieve payment credentials
[**update_purchase_intent**](AgentCapabilitiesApi.md#update_purchase_intent) | **PUT** /icc/v1/instructions/{instructionId} | Update a purchase intent


# **cancel_purchase_intent**
> AgenticCreatePurchaseIntentResponse200 cancel_purchase_intent(instruction_id, agentic_cancel_purchase_intent_request)

Cancel a purchase intent

Cancel an existing purchase intent (instruction) identified by its instructionId. The agent calls this endpoint when the consumer decides to abandon the purchase before payment credentials have been used. Requires device information and assurance data for identity verification. Returns status CANCELLED (HTTP 200) on success, or PENDING (HTTP 202) with pendingEvents if cardholder authentication is required before cancellation can proceed.

### Example
```ruby
# load the gem
require 'cybersource_rest_client'

api_instance = CyberSource::AgentCapabilitiesApi.new

instruction_id = 'instruction_id_example' # String | 

agentic_cancel_purchase_intent_request = CyberSource::AgenticCancelPurchaseIntentRequest.new # AgenticCancelPurchaseIntentRequest | Unique identifier for the purchase intent instruction.


begin
  #Cancel a purchase intent
  result = api_instance.cancel_purchase_intent(instruction_id, agentic_cancel_purchase_intent_request)
  p result
rescue CyberSource::ApiError => e
  puts "Exception when calling AgentCapabilitiesApi->cancel_purchase_intent: #{e}"
end
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **instruction_id** | **String**|  | 
 **agentic_cancel_purchase_intent_request** | [**AgenticCancelPurchaseIntentRequest**](AgenticCancelPurchaseIntentRequest.md)| Unique identifier for the purchase intent instruction. | 

### Return type

[**AgenticCreatePurchaseIntentResponse200**](AgenticCreatePurchaseIntentResponse200.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json;charset=utf-8
 - **Accept**: application/hal+json;charset=utf-8



# **confirm_transaction_events**
> AgenticConfirmTransactionEventsResponse202 confirm_transaction_events(instruction_id, agentic_confirm_transaction_events_request)

Confirm transaction events

Confirm transaction events for a completed purchase. The agent calls this endpoint after the payment has been submitted to notify the Intelligent Commerce Connect of the transaction outcome. The request includes processor information (transaction type, status, approval codes), order details (shipping, tracking, product information), and merchant information. Returns HTTP 202 acknowledging receipt of the confirmation.

### Example
```ruby
# load the gem
require 'cybersource_rest_client'

api_instance = CyberSource::AgentCapabilitiesApi.new

instruction_id = 'instruction_id_example' # String | Unique identifier for the purchase intent instruction.

agentic_confirm_transaction_events_request = CyberSource::AgenticConfirmTransactionEventsRequest.new # AgenticConfirmTransactionEventsRequest | 


begin
  #Confirm transaction events
  result = api_instance.confirm_transaction_events(instruction_id, agentic_confirm_transaction_events_request)
  p result
rescue CyberSource::ApiError => e
  puts "Exception when calling AgentCapabilitiesApi->confirm_transaction_events: #{e}"
end
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **instruction_id** | **String**| Unique identifier for the purchase intent instruction. | 
 **agentic_confirm_transaction_events_request** | [**AgenticConfirmTransactionEventsRequest**](AgenticConfirmTransactionEventsRequest.md)|  | 

### Return type

[**AgenticConfirmTransactionEventsResponse202**](AgenticConfirmTransactionEventsResponse202.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json;charset=utf-8
 - **Accept**: application/hal+json;charset=utf-8



# **enroll_card**
> AgenticCardEnrollmentResponse200 enroll_card(agentic_card_enrollment_request)

Enroll a card

Enroll a payment card for agentic or e-commerce transactions. This is typically the first step in the Intelligent Commerce payment lifecycle — the agent calls this endpoint to register a consumer's card, creating a tokenized reference that can be used in subsequent purchase instructions and payment credential retrieval. Requires device information, consumer identity, billing details, and payment instrument references. Returns a status of ACTIVE (HTTP 200) if enrollment completes immediately, or PENDING (HTTP 202) with pendingEvents if cardholder authentication is required. Call this endpoint when a consumer wants to add a new payment card or when setting up a card for agentic payment flows.

### Example
```ruby
# load the gem
require 'cybersource_rest_client'

api_instance = CyberSource::AgentCapabilitiesApi.new

agentic_card_enrollment_request = CyberSource::AgenticCardEnrollmentRequest.new # AgenticCardEnrollmentRequest | 


begin
  #Enroll a card
  result = api_instance.enroll_card(agentic_card_enrollment_request)
  p result
rescue CyberSource::ApiError => e
  puts "Exception when calling AgentCapabilitiesApi->enroll_card: #{e}"
end
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **agentic_card_enrollment_request** | [**AgenticCardEnrollmentRequest**](AgenticCardEnrollmentRequest.md)|  | 

### Return type

[**AgenticCardEnrollmentResponse200**](AgenticCardEnrollmentResponse200.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json;charset=utf-8
 - **Accept**: application/hal+json;charset=utf-8



# **initiate_purchase_intent**
> AgenticCreatePurchaseIntentResponse200 initiate_purchase_intent(agentic_create_purchase_intent_request)

Initiate a purchase intent

Create a new purchase intent (instruction) for an agentic transaction. The agent calls this endpoint after a card has been enrolled to define what the consumer wants to buy. The request includes payment instrument references, device and assurance data, mandates (spending limits, merchant preferences, and product descriptions), and optional buyer information. Return an instructionId (HTTP 200) if the intent is created immediately, or PENDING (HTTP 202) with pendingEvents if cardholder authentication is required. The instructionId returned is used in all subsequent operations - update, cancel, retrieve credentials, and confirm transaction.

### Example
```ruby
# load the gem
require 'cybersource_rest_client'

api_instance = CyberSource::AgentCapabilitiesApi.new

agentic_create_purchase_intent_request = CyberSource::AgenticCreatePurchaseIntentRequest.new # AgenticCreatePurchaseIntentRequest | 


begin
  #Initiate a purchase intent
  result = api_instance.initiate_purchase_intent(agentic_create_purchase_intent_request)
  p result
rescue CyberSource::ApiError => e
  puts "Exception when calling AgentCapabilitiesApi->initiate_purchase_intent: #{e}"
end
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **agentic_create_purchase_intent_request** | [**AgenticCreatePurchaseIntentRequest**](AgenticCreatePurchaseIntentRequest.md)|  | 

### Return type

[**AgenticCreatePurchaseIntentResponse200**](AgenticCreatePurchaseIntentResponse200.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json;charset=utf-8
 - **Accept**: application/hal+json;charset=utf-8



# **retrieve_payment_credentials**
> AgenticRetrievePaymentCredentialsResponse200 retrieve_payment_credentials(instruction_id, agentic_retrieve_payment_credentials_request)

Retrieve payment credentials

Retrieve tokenized payment credentials for a purchase intent to complete the transaction at a merchant. The agent calls this endpoint after a purchase intent has been created and approved, providing transaction-level details including order information, merchant details, payment options, and production information. Returns COMPLETED (HTTP 200) with a signed payload containing encrypted payment credentials (authorization token and JWS-signed payload), or PENDING (HTTP 202) with pendingEvents if additional cardholder authentication is required. The signed payload is used by the merchant's payment processor to complete the transaction.

### Example
```ruby
# load the gem
require 'cybersource_rest_client'

api_instance = CyberSource::AgentCapabilitiesApi.new

instruction_id = 'instruction_id_example' # String | Unique identifier for the purchase intent instruction.

agentic_retrieve_payment_credentials_request = CyberSource::AgenticRetrievePaymentCredentialsRequest.new # AgenticRetrievePaymentCredentialsRequest | 


begin
  #Retrieve payment credentials
  result = api_instance.retrieve_payment_credentials(instruction_id, agentic_retrieve_payment_credentials_request)
  p result
rescue CyberSource::ApiError => e
  puts "Exception when calling AgentCapabilitiesApi->retrieve_payment_credentials: #{e}"
end
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **instruction_id** | **String**| Unique identifier for the purchase intent instruction. | 
 **agentic_retrieve_payment_credentials_request** | [**AgenticRetrievePaymentCredentialsRequest**](AgenticRetrievePaymentCredentialsRequest.md)|  | 

### Return type

[**AgenticRetrievePaymentCredentialsResponse200**](AgenticRetrievePaymentCredentialsResponse200.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json;charset=utf-8
 - **Accept**: application/hal+json;charset=utf-8



# **update_purchase_intent**
> AgenticCreatePurchaseIntentResponse200 update_purchase_intent(instruction_id, agentic_update_purchase_intent_request)

Update a purchase intent

Update an existing purchase intent (instruction) identified by its instructionId. The agent calls this endpoint when the consumer modifies their order — for example, changing the quantity, updating mandates, switching payment instruments, or changing shipping details. The request body has the same structure as the initiate request. Returns the same instructionId (HTTP 200) on success, or PENDING (HTTP 202) with pendingEvents if additional cardholder authentication is required for the updated intent.

### Example
```ruby
# load the gem
require 'cybersource_rest_client'

api_instance = CyberSource::AgentCapabilitiesApi.new

instruction_id = 'instruction_id_example' # String | Unique identifier for the purchase intent instruction.

agentic_update_purchase_intent_request = CyberSource::AgenticUpdatePurchaseIntentRequest.new # AgenticUpdatePurchaseIntentRequest | 


begin
  #Update a purchase intent
  result = api_instance.update_purchase_intent(instruction_id, agentic_update_purchase_intent_request)
  p result
rescue CyberSource::ApiError => e
  puts "Exception when calling AgentCapabilitiesApi->update_purchase_intent: #{e}"
end
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **instruction_id** | **String**| Unique identifier for the purchase intent instruction. | 
 **agentic_update_purchase_intent_request** | [**AgenticUpdatePurchaseIntentRequest**](AgenticUpdatePurchaseIntentRequest.md)|  | 

### Return type

[**AgenticCreatePurchaseIntentResponse200**](AgenticCreatePurchaseIntentResponse200.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json;charset=utf-8
 - **Accept**: application/hal+json;charset=utf-8



