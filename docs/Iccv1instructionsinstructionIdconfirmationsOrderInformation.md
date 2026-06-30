# CyberSource::Iccv1instructionsinstructionIdconfirmationsOrderInformation

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**order_id** | **String** | Unique identifier for the order | [optional] 
**order_status** | **String** | Status of the order | [optional] 
**order_date** | **String** | Order date (UTC time in Epoch format) | [optional] 
**expected_delivery_date** | **String** | Expected delivery date for the order (UTC time in Epoch format) | [optional] 
**amount_detail** | [**IccAmountDetail**](IccAmountDetail.md) |  | [optional] 
**ship_to** | [**Iccv1instructionsinstructionIdcredentialsOrderInformationShipTo**](Iccv1instructionsinstructionIdcredentialsOrderInformationShipTo.md) |  | [optional] 
**shipping_details** | [**IccShippingDetails**](IccShippingDetails.md) |  | [optional] 
**tracking_id** | **String** | Tracking ID for the shipment | [optional] 
**carrier** | **String** | Shipping carrier or provider | [optional] 
**line_items** | [**Array&lt;Iccv1instructionsinstructionIdcredentialsOrderInformationLineItems&gt;**](Iccv1instructionsinstructionIdcredentialsOrderInformationLineItems.md) |  | [optional] 


