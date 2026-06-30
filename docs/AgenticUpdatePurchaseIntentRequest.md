# CyberSource::AgenticUpdatePurchaseIntentRequest

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**client_correlation_id** | **String** | Client Correlation Id used during the tokenization or during FIDO assertion. | 
**payment_information** | [**Iccv1tokensPaymentInformation**](Iccv1tokensPaymentInformation.md) |  | 
**device_information** | [**Iccv1tokensDeviceInformation**](Iccv1tokensDeviceInformation.md) |  | 
**assurance_data** | [**Array&lt;Iccv1tokensAssuranceData&gt;**](Iccv1tokensAssuranceData.md) | Assurance data. | 
**mandates** | [**Array&lt;Iccv1instructionsMandates&gt;**](Iccv1instructionsMandates.md) |  | 
**buyer_information** | [**Iccv1tokensBuyerInformation**](Iccv1tokensBuyerInformation.md) |  | [optional] 
**consumer_prompt** | **String** | Recap - A summary or condensed version of user prompts that leads to the purchase. | [optional] 


