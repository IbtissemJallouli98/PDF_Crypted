/**
 * @description       : Apex class managing the document upload on a signature request in Yousign
 * @author            : Simon Persenot
 * @group             : INVOCABLE
 * @last modified on  : 04-12-2023
 * @last modified by  : Simon Persenot
 * @testCoverage      : YS_INVOCABLE_UploadDocument_Test
**/
public with sharing class YS_INVOCABLE_UploadDocument {
    private static final String ENDPOINT = '/signature_requests/{0}/documents';
    private static final String METHOD = 'POST';
    @testVisible private static final String CLASS_NAME = 'YS_INVOCABLE_UploadDocument';
    
    /**
    * @description upload a document to a signature request on Yousign
    * @author Simon Persenot | 04-12-2023 
    * @param inputs configuration for the signature request
    * @return List<Response> 
    **/
    @InvocableMethod(
        label='[YS] Upload a document'
        description='Upload a document for a Signature Request. For more information please consult Yousign Public API'
        category='YS'
        iconName='slds:standard:document'
        callout='true'
    )
    public static List<Response> doRestCall(List<UploadDocumentData> inputs)
    {
        Response res;
        try
        {
            UploadDocumentData input = inputs[0];
            input.checkValidity();

            HttpRequest request = YS_Service.constructRequest(METHOD, ENDPOINT, new List<String>{ input.signatureRequestId });

            ContentDocument cd = [SELECT Id, Title, FileExtension, LatestPublishedVersion.VersionData FROM ContentDocument WHERE Id= :input.fileId LIMIT 1];

            request.setHeader('Content-Type', YS_MultipartUtil.GetContentType());
            /*
                * QUICK LOGIC SUMM UP HERE (for the brave ones that want to understand the inner mechanisms)
                what we want to endup with here is:
                - multipart data form
                - everything as a Blob to be passed as request body

                constraints:
                - sf does not manage natively multiform data part
                - sf files are Blobs and encoded into base64 String

                body example:
                    --1ff13444ed8140c7a32fc4e6451aa76d
                    Content-Disposition: form-data; name="nature"

                    signable_document
                    --1ff13444ed8140c7a32fc4e6451aa76d
                    Content-Disposition: form-data; name="parse_anchors"

                    true
                    --1ff13444ed8140c7a32fc4e6451aa76d
                    Content-Disposition: form-data; name="file"; filename="temp70.pdf"
                    Content-Type: application/pdf
                    
                    <the document body e.g.>JVBERi0xLjcKJbXtrvsKNCAwIG9iago8PCAvTGVuZ3RoIDUgMCBSCiAgIC9GaWx0ZXIgL0ZsYXRlRGVjb2RlCj4+CnN0cmVhbQp4nDWMTQ5AQAyF9z3Fu4BOy5gZexewshbBCsHG8dVfvqYvec1XhRiZ2tLACf1MGzXYSJ7mnn1Ai4WEC68aA4RTHn1pCodSqoR9gusE0
                                    
                    --1ff13444ed8140c7a32fc4e6451aa76d--  

                how does it works:
                1. we store everything before the document body in a string (beforeFile)
                2. we store the file body as a base64 string (file)
                3. we store everything after the document body in a string (afterFile)
                4. we transform the beforeFile and afterFile to a base64 String
                5. we decode everything as a single blob to make it the request body 🤯

                Difficulties managed in YS_MultipartUtil:
                - formating to multipart
                - when converting the file to base64, it uses padding to fill the missing extra octets. More info in YS_MultipartUtil on that
            */
            String body = '';
            String beforeFile = '';
            String file;
            String afterFile = '';
            beforeFile += YS_MultipartUtil.WriteBoundary(false);
            beforeFile += YS_MultipartUtil.WriteBodyParameter('nature', input.nature, false);
            beforeFile += YS_MultipartUtil.WriteBoundary(false);
            if (input.useSmartAnchors)
            {
                beforeFile += YS_MultipartUtil.WriteBodyParameter('parse_anchors', String.valueOf(input.useSmartAnchors), false);
                beforeFile += YS_MultipartUtil.WriteBoundary(false);
            }
            
            YS_MultipartUtil.FileParamResponse fpr = YS_MultipartUtil.WriteFileBodyParameter('file', EncodingUtil.base64Encode(cd.LatestPublishedVersion.VersionData), cd.Title + '.' + cd.FileExtension, false);
            beforeFile += fpr.before;
            file = fpr.file;
            afterFile += YS_MultipartUtil.WriteEndingBoundary(false);

            body += YS_MultipartUtil.SafelyPad(beforeFile, '\r\n\r\n', true);
            body += file;
            body += YS_MultipartUtil.SafelyPad(afterFile, '\r\n\r\n', true);
            request.setBodyAsBlob(EncodingUtil.base64Decode(body));

            HttpResponse response = new Http().send(request);

            res = new Response(response);
        }
        catch (Exception e)
        {
            res = new Response(e.getMessage());
        }

        return new List<Response>{ res };
    }

    

    public class UploadDocumentData
    {
        //INVOCABLE VARIABLES
        @InvocableVariable(label='Signature Request Id' description='Id of the Signature Request (SR) in Yousign' Required=true)
        public String signatureRequestId;
        @InvocableVariable(label='File Id' description='ContentDocument Id in Salesforce that must be uploaded' Required=true)
        public String fileId;
        @InvocableVariable(label='Document Nature' description='Nature of the document in regards to the SR. Available values are \'attachment\', \'signable_document\'' Required=true)
        public String nature;
        @InvocableVariable(label='Smart Anchors ?' description='Use smart anchors ?')
        public Boolean useSmartAnchors;

        public void checkValidity()
        {
            if(String.isBlank(this.signatureRequestId) || String.isBlank(this.fileId) || String.isBlank(this.nature))
            {
                throw new YS_Utils.WrappedException(YS_Utils.ERR_NULL_PARAM, CLASS_NAME);
            }
            if (this.useSmartAnchors == null)
            {
                this.useSmartAnchors = false;
            }
        }
    }

    public class Response
    {
        @InvocableVariable
        public Boolean	      success;
        @InvocableVariable
        public Integer	      statusCode;
        @InvocableVariable
        public ExternalService.YS_Document yousignDocument;
        @InvocableVariable
        public String	      errorMessage;

        public Response(String error)
        {
            this.success       = false;
            this.errorMessage  = error;
        }

        public Response(HttpResponse res)
        {
            this.statusCode = res?.getStatusCode();
            this.success    = this.statusCode == 201;
            if (success)
            {
                yousignDocument = (ExternalService.YS_Document) JSON.deserialize(res?.getBody(), ExternalService.YS_Document.class);
                // get values that are url encoded and not 
                Map<String, Object> docUntyped = (Map<String, Object>) JSON.deserializeUntyped(res?.getBody());
                yousignDocument.contentx5ftype = (String) docUntyped.get('content_type');
                yousignDocument.isx5fprotected = (Boolean) docUntyped.get('is_protected');
                yousignDocument.isx5fsigned = (Boolean) docUntyped.get('is_signed');
                yousignDocument.totalx5fpages = (Integer) docUntyped.get('total_pages');
                yousignDocument.isx5flocked = (Boolean) docUntyped.get('is_locked');
                yousignDocument.totalx5fanchors = (Integer) docUntyped.get('total_anchors');
            }
            else
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
                    when 403
                    {
                        this.errorMessage = 'Access forbidden';
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