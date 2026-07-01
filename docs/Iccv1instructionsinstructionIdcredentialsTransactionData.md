# CyberSource::Iccv1instructionsinstructionIdcredentialsTransactionData

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**client_reference_information** | [**Iccv1instructionsinstructionIdcredentialsClientReferenceInformation**](Iccv1instructionsinstructionIdcredentialsClientReferenceInformation.md) |  | 
**mandate_reference_data** | [**Array&lt;Iccv1instructionsinstructionIdcredentialsMandateReferenceData&gt;**](Iccv1instructionsinstructionIdcredentialsMandateReferenceData.md) | Mandate Reference Data. | [optional] 
**type** | **String** | (Conditional) Type of the transaction. This field is used to determine the type of transaction and the associated processing rules.   Possible values:     - &#x60;PURCHASE&#x60; (Default)   - &#x60;BILL_PAYMENT&#x60;   - &#x60;MONEY_TRANSFER&#x60;   - &#x60;DISBURSEMENT&#x60;   - &#x60;P2P&#x60;  | [optional] 
**order_information** | [**Iccv1instructionsinstructionIdcredentialsOrderInformation**](Iccv1instructionsinstructionIdcredentialsOrderInformation.md) |  | 
**payment_service_provider_url** | **String** | (Conditional) URL of the payment service provider. | [optional] 
**payment_service_provider_name** | **String** | (Conditional) Name of the payment service provider. | [optional] 
**merchant_order_id** | **String** | (Conditional) Digital Payment Application generated order/invoice number corresponding to a Consumer purchase. | [optional] 
**merchant_information** | [**Iccv1instructionsinstructionIdcredentialsMerchantInformation**](Iccv1instructionsinstructionIdcredentialsMerchantInformation.md) |  | 
**payment_options** | [**Iccv1instructionsinstructionIdcredentialsPaymentOptions**](Iccv1instructionsinstructionIdcredentialsPaymentOptions.md) |  | [optional] 
**attachments** | [**Array&lt;Iccv1instructionsinstructionIdcredentialsAttachments&gt;**](Iccv1instructionsinstructionIdcredentialsAttachments.md) |  | [optional] 


