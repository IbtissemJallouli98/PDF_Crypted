/**
 * @description       : Service class for YS x SF integration
 * @author            : Simon Persenot
 * @group             : 
 * @last modified on  : 13-12-2023
 * @last modified by  : Simon Persenot
 * @testCoverage      : YS_Service_Test
**/
public with sharing class YS_Service {
    private static final String BASE_PATH = '/v3';
    @testVisible private static final Integer TIMEOUT = 10000;

    /**
    * @description return the name of the NameCredential to use
    * @author Simon Persenot | 12-12-2023 
    * @return String 
    **/
    public static String getNameCredentials()
    {
        String namedCredential = 'YS_Sandbox';
        YS_Configuration__c orgDefault = YS_Configuration__c.getOrgDefaults();
       /* if (orgDefault.IsSandbox__c)
        {
            namedCredential = 'YS_Sandbox';
        }
        else
        {
            namedCredential = 'YS_Prod';
        } 
            */
        return namedCredential;
    }

    /**
    * @description return the encoding key of Yousign Webservice
    * @author Simon Persenot | 12-12-2023 
    * @return String 
    **/
    public static String getEncodingKey()
    {
        String key;
        YS_Configuration__c orgDefault = YS_Configuration__c.getOrgDefaults();
        return orgDefault.YS_EncodingKey__c;
    }

    /**
    * @description Construct endpoint for a callout to the Yousign API
    * @author Simon Persenot | 29-05-2024 
    * @param endpoint endpoint to call as shown in the Yousign API documentation
    * @param params ordered list of variables to place in the endpoint
    * @return String 
    **/
    public static String getEndpoint(String endpoint, List<String> params)
    {
        return 'callout:' + getNameCredentials() + BASE_PATH + (params == null || params.isEmpty() ? endpoint : String.format(endpoint, params));
    }

    /**
    * @description get default timeout for callouts
    * @author Simon Persenot | 29-05-2024 
    * @return Integer 
    **/
    public static Integer getTimeout()
    {
        return TIMEOUT;
    }

    /**
    * @description Contruct the base HTTP request for a callout to the Yousign API
    * @author Simon Persenot | 29-05-2024 
    * @param method GET, POST, PUT, DELETE
    * @param endpoint endpoint to call as shown in the Yousign API documentation
    * @param params ordered list of variables to place in the endpoint
    * @return HttpRequest 
    **/
    public static HttpRequest constructRequest(String method, String endpoint, List<String> params)
    {
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint(getEndpoint(endpoint, params));
        request.setTimeout(getTimeout());
        return request;
    }
}