@isTest
public with sharing class YS_DataTestFactory {
    public static final Datetime EVENT_TIME = Datetime.newInstance(2023, 10, 28, 11, 30, 00);
    public static final String SR_ID = 'abcdef01-abce-abdc-abcd-abcdef012345';
    public static final String SIGNER_ID = 'abcdef01-abce-abdc-abcd-123456789012';

    public static YS_WebhookListener.WebhookPayload getPayload(String useCase)
    {
        YS_WebhookListener.WebhookPayload payload = new YS_WebhookListener.WebhookPayload();
        payload.event_id = 'event_id';
        payload.event_time = String.valueOf(EVENT_TIME.getTime()).removeEnd('000');
        payload.subscription_id = 'my-subscription-id';
        payload.subscription_description = 'test-webhook';
        payload.sandbox = false;
        payload.data = new YS_WebhookListener.WebhookPayloadData();

        switch on useCase {
            when 'signature_request' {
                payload.event_name = 'signature_request.done';
                payload.data.signature_request = new ExternalService.YS_SignatureRequest();
                payload.data.signature_request.id = SR_ID;
                payload.data.signature_request.status = 'done';
            }
            when 'signer' {
                payload.event_name = 'signer.done';
                payload.data.signer = new ExternalService.YS_Signer();
                payload.data.signer.id = SIGNER_ID;
                payload.data.signer.status = 'signed';
            }
            when 'approver' {
                payload.event_name = 'approver.approved';
                payload.data.approver = new ExternalService.YS_Approver();
                payload.data.approver.id = 'random-id';
            }
            when else {
                payload.event_name = null;
            }
        }

        return payload;
    }

    public static YS_SignatureRequest__c createSignatureRequest()
    {
        return new YS_SignatureRequest__c(
            Name = 'My Signature Request',
            ExternalId__c = SR_ID,
            Status__c = 'ongoing',
            DeliveryMode__c = 'none'
        );
    }

    public static YS_Signer__c createSigner(String srId)
    {
        return new YS_Signer__c(
            Name = 'Jean-Claude Signer',
            ExternalId__c = SIGNER_ID,
            Status__c = 'initiated',
            Email__c = 'jeanclaude.signer@example.test',
            FirstName__c = 'Jean-Claude',
            LastName__c = 'Signer',
            Locale__c = 'fr',
            Phone__c = '+33612121212',
            SignatureAuthenticationMode__c = 'no_otp',
            SignatureLevel__c = 'electronic_signature',
            SignatureRequest__c = srId
        );
    }

    public static ContentVersion createContentVersion() {
        return new ContentVersion(
            Title          = 'ReallyNiceDocument',
            PathOnClient   = 'ReallyNiceDocument.pdf',
            VersionData    = Blob.valueOf('This is really Nice, and i am not talking about the French city'),
            IsMajorVersion = true
        );
    }
}