/**
 * @description       : Use this class to make HTTP call in multipart/form-data type.
 *                    : Adapted from this code : https://github.com/muenzpraeger/salesforce-einstein-vision-apex/blob/master/src/classes/EinsteinVision_HttpBodyPart.cls.
 *                    : The previous code mentioned above is part of a project that is licensed under the Apache License Version 2.0
 *                    : The whole Licence can be found here: https://github.com/muenzpraeger/salesforce-einstein-vision-apex/blob/master/LICENSE.md
 * @author            : Simon Persenot
 * @group             : 
 * @last modified on  : 24-07-2023
 * @last modified by  : Simon Persenot
 * @testCoverage      : YS_MultipartUtil_Test
**/
public with sharing class YS_MultipartUtil {
    @testVisible private static final String CLASS_NAME = 'YS_MultipartUtil';
    
    //  The boundary is alligned so it doesn't produce padding characters when base64 encoded with -- or \r\n
    private final static String Boundary = '1ff13444ed8140c7a32fc4e6451aa76d';


    /**
    * @description Getter for the boundary
    * @author Simon Persenot | 16-05-2024 
    * @return String 
    **/
    public static String getBoundary() {
        return Boundary;
    }

    /**
    * @description Returns the request's content type for multipart/form-data requests.
    * @author Simon Persenot | 16-05-2024 
    * @return String 
    **/
    public static String getContentType() {
        return 'multipart/form-data; charset="UTF-8"; boundary="' + Boundary + '"';
    }

    /**
    * @description Pad the value with spaces until the base64 encoding is no longer padded.
    * @author Simon Persenot | 16-05-2024 
    * @param value 
    * @param lineBreaks 
    * @param encode64 
    * @return String 
    **/
    public static String safelyPad(string value, string lineBreaks, Boolean encode64)
    {
        while (value.endsWith(lineBreaks))
        {
            value = value.removeEnd(lineBreaks);
        }

        String valueCrLf = value + lineBreaks;

        if (!encode64)
        {
            return valueCrLf;
        }

        blob valueCrLfBlob = blob.valueOf(valueCrLf);
        String valueCrLf64 = EncodingUtil.base64Encode(valueCrLfBlob);

        while (valueCrLf64.endsWith('=')) {
            value += ' ';
            valueCrLf = value + lineBreaks;
            valueCrLfBlob = Blob.valueOf(valueCrLf);
            valueCrLf64 = EncodingUtil.base64Encode(valueCrLfBlob);
        }

        return valueCrLf64;
    }

    /**
    * @description Write a multipart form boundary between parameters of the form's body
    * @author Simon Persenot | 16-05-2024 
    * @param encode64 
    * @return string 
    **/
    public static string writeBoundary(Boolean encode64) {
        string value = '--' + Boundary + '\r\n';
        blob valueBlob = blob.valueOf(value);

        return encode64 ? EncodingUtil.base64Encode(valueBlob) : value;
    }

    /**
    * @description Write the multipart form ending boundary between parameters of the form's body
    * @author Simon Persenot | 16-05-2024 
    * @param encode64 
    * @return string 
    **/
    public static string writeEndingBoundary(Boolean encode64) {
        string value = '--' + Boundary + '--';
        blob valueBlob = blob.valueOf(value);

        System.debug(value);
        return encode64 ? EncodingUtil.base64Encode(valueBlob) : value;
    }

    /**
    * @description Write a key-value pair to the form's body in multipart data format.
    * @author Simon Persenot | 16-05-2024 
    * @param key 
    * @param value 
    * @param encode64 
    * @return string 
    **/
    public static string writeBodyParameter(string key, string value, Boolean encode64) {

        string contentDisposition = 'Content-Disposition: form-data; name="' + key + '"';
        string content = safelyPad(contentDisposition, '\r\n\r\n', encode64);
        content += safelyPad(value, '\r\n', encode64);

        return content;
    }

    /**
    * @description Write the file body parameter to the form's body in multipart data format. Safely pads both the file and the multipart syntax before the file.
    * @author Simon Persenot | 16-05-2024 
    * @param key 
    * @param file64 
    * @param fileName 
    * @param encode64 
    * @return FileParamResponse 
    **/
    public static FileParamResponse writeFileBodyParameter(String key, String file64, String fileName, Boolean encode64) {
        String mimeType = resolveMimeType(fileName);
        FileParamResponse res = new FileParamResponse();
        
        String contentDisposition = 'Content-Disposition: form-data; name="' + key + '"; filename="'+fileName+'"';
        res.before = safelyPad(contentDisposition, '\r\n', encode64);
        
        String contentTypeHeader = 'Content-Type: ' + mimeType;
        res.before += safelyPad(contentTypeHeader, '\r\n\r\n', encode64);

        
        // * the idea here is to avoid some char being added for encoding purposes. Check comms below for more understanding. 
        Integer file64Length = file64.length();
        String last4Bytes = file64.substring(file64.length()-4,file64.length());

        // Avoid padding the file data with spaces, which safelyPad does
        // http://salesforce.stackexchange.com/a/33326/102

        // when converting binary to base64 it converts each 3 octets (24 bits) to 4 base64 digits (24 octets too)
        // at the end of the file, if there isn't 3 relevent octets but 1 or 2 it fills the missing ones with padding.

        if (last4Bytes.endsWith('==')) {
            // The '==' sequence indicates that the last group contained only one 8 bit byte
            // 8 digit binary representation of CR is 00001101
            // 8 digit binary representation of LF is 00001010
            // Stitch them together and then from the right split them into 6 bit chunks
            // 0000110100001010 becomes 0000 110100 001010
            // Note the first 4 bits 0000 are identical to the padding used to encode the
            // second original 6 bit chunk, this is handy it means we can hard code the response in
            // The decimal values of 110100 001010 are 52 10
            // The base64 mapping values of 52 10 are 0 K
            // See http://en.wikipedia.org/wiki/Base64 for base64 mapping table
            // Therefore, we replace == with 0K
            // Note: if using \n\n instead of \r\n replace == with 'oK'
            last4Bytes = last4Bytes.substring(0,2) + '0K';
            file64 = file64.substring(0,file64.length()-4) + last4Bytes;
            // We have appended the \r\n to the Blob, so leave footer as it is.
        } else if (last4Bytes.endsWith('=')) {
            // '=' indicates that encoded data already contained two out of 3x 8 bit bytes
            // We replace final 8 bit byte with a CR e.g. \r
            // 8 digit binary representation of CR is 00001101
            // Ignore the first 2 bits of 00 001101 they have already been used up as padding
            // for the existing data.
            // The Decimal value of 001101 is 13
            // The base64 value of 13 is N
            // Therefore, we replace = with N
            last4Bytes = last4Bytes.substring(0,3) + 'N';
            file64 = file64.substring(0,file64.length()-4) + last4Bytes;
            // We have appended the CR e.g. \r, still need to prepend the line feed to the footer
            file64 += EncodingUtil.base64Encode(Blob.valueOf('\n\r\n')); // adding an extra one to prevent padding (Cg0K)
        }
        else
        {
            // nothing was appended, need full addition
            file64 += EncodingUtil.base64Encode(Blob.valueOf('\r\n\r\n\r\n'));// adding 3 instead of 1 to prevent padding (DQoNCg0K)
        }
        res.file = file64;
        
        return res;
    }
    
    /**
    * @description Check the mime type of the file to be uploaded. Only PDF is supported for as it others types are not supported by Yousign API.
    * @author Simon Persenot | 16-05-2024 
    * @param fileName 
    * @return String 
    **/
    @testVisible
    private static String resolveMimeType(String fileName) {
        String fileType = fileName.substringAfterLast('.');
        if (fileType.equalsIgnoreCase('pdf')) {
            return 'application/pdf';            
        }
        throw new YS_Utils.WrappedException('Unsupported file type: ' + fileType + '. PDF is the only supported types.', CLASS_NAME);
    }

    /**
     * Class to store the response of the file body parameter.
     * The idea here is to separate the file from the the multipart syntax before the file to avoid padding issues.
     */
    public class FileParamResponse
    {
        public String before;
        public String file;

        public FileParamResponse()
        {
            before = '';
            file = '';
        }
    }
}