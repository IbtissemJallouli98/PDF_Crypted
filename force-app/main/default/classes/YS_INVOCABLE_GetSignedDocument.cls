/**
 * @description       : Retrieve the signed document of a signature request in Yousign and attach it to the Signature Request in Salesforce
 * @author            : Simon Persenot
 * @group             : INVOCABLE
 * @last modified on  : 23-05-2024
 * @last modified by  : Simon Persenot
 * @testCoverage      : YS_INVOCABLE_GetSignedDocument_Test
**/
public without sharing class YS_INVOCABLE_GetSignedDocument {
    private static final String ENDPOINT = '/signature_requests/{0}/documents/download';
    private static final String METHOD = 'GET';
    @testVisible private static final String CLASS_NAME = 'YS_INVOCABLE_GetSignedDocument';

    /**
    * @description Get the signed documents of a signature request in Yousign
    * @author Simon Persenot | 18-12-2023 
    * @param srIds ids of the signature requests
    * @return List<Response> 
    **/
    @InvocableMethod(
        label='[YS] Get Signed Documents'
        description='Get documents of a Signature Request. For more information please consult Yousign Public API'
        category='YS'
        iconName='slds:standard:document'
        callout='true'
    )
    public static List<Response> getDocuments(List<String> srIds) {
        Response res;
        
        if (srIds == null || srIds.size() != 1)
        {
            throw new YS_Utils.WrappedException(YS_Utils.ERR_UNSUPORTED_DATA, CLASS_NAME);
        }

        try {
            HttpRequest request = YS_Service.constructRequest(METHOD, ENDPOINT, new List<String>{ srIds[0] });
			
            HttpResponse response = new Http().send(request);
            res = new Response(response);

            if (res.success)
            {
                String contentDispo = response.getHeader('Content-Disposition'); // attachment; filename=Q1-1-My-Quote-2023-11-06-signed.pdf; filename*=utf-8\'\'Q1-1%20-%20My%20Quote%20-%202023-11-06%20%28signed%29.pdf
                String fileNameUtf8 = contentDispo.substringAfter('filename*=utf-8\'\'');
                String decodeFileName = EncodingUtil.urlDecode(fileNameUtf8, 'UTF-8');
                String decodeFileNameWoExt = decodeFileName.substringBeforeLast('.');
                
                // insert the document retrieved
                ContentVersion cv = new ContentVersion();
                cv.ContentLocation = 'S';
                cv.PathOnClient = decodeFileName;
                cv.Origin = 'C';
                cv.Title = decodeFileNameWoExt;
                cv.VersionData = response.getBodyAsBlob();
                insert cv;

                //link it to the Signature Request
                ContentDocumentLink cdl = new ContentDocumentLink();
                YS_SignatureRequest__c sr = [SELECT Id FROM YS_SignatureRequest__c WHERE ExternalId__c = :srIds[0]];
                cdl.LinkedEntityId = sr.Id;
                cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
                cdl.ShareType = 'I';
                insert cdl;
            }
        }
        catch (Exception e)
        {
            res = new Response(e.getMessage());
        }

        return new List<Response>{ res };
    }

    public class Response
    {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public Integer statusCode;
        @InvocableVariable
        public String  errorMessage;

        public Response(String error)
        {
            this.success       = false;
            this.errorMessage  = error;
        }

        public Response(HttpResponse res)
        {
            this.statusCode = res?.getStatusCode();
            this.success    = this.statusCode == 200;
            if (!success)
            {
                switch on statusCode
                {
                    when 400
                    {
                        ExternalService.YS_ViolationResponse rep400 = (ExternalService.YS_ViolationResponse) JSON.deserialize(res?.getBody(), ExternalService.YS_ViolationResponse.class);
                        this.errorMessage = rep400.detail_set != null && rep400.detail_set ? rep400.detail : (rep400.z0type_set != null && rep400.z0type_set ? rep400.z0type : '');
                    }
                    when 401
                    {
                        ExternalService.YS_getx5fsignaturex5frequestsx5f401x5fresponse rep401 = (ExternalService.YS_getx5fsignaturex5frequestsx5f401x5fresponse) JSON.deserialize(res?.getBody(), ExternalService.YS_getx5fsignaturex5frequestsx5f401x5fresponse.class);
                        this.errorMessage = rep401.detail;
                    }
                    when 404
                    {
                        this.errorMessage = 'Resource not found';
                    }
                    when else
                    {
                        this.errorMessage = res.getStatus();
                    }
                }
            }
        }
    }
}