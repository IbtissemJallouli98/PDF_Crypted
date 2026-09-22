/**
 * @description       : Apex class containing utility methods used in the Yousign package
 * @author            : Simon Persenot
 * @group             : 
 * @last modified on  : 23-05-2024
 * @last modified by  : Simon Persenot
 * @testCoverage      : 
**/
public with sharing class YS_Utils {
    public final static String ERR_MISSING_PROPERTIES      = 'ERR_MISSING_PROPERTIES';
    public final static String ERR_NOT_FOUND               = 'ERR_NOT_FOUND';
    public final static String ERR_NO_DATA                 = 'ERR_NO_DATA';
    public final static String ERR_NULL_PARAM              = 'ERR_NULL_PARAM';
    public final static String ERR_UNSUPORTED_DATA         = 'ERR_UNSUPORTED_DATA';
    public final static String ERR_UNOVERRIDDEN_METHOD     = 'ERR_UNOVERRIDDEN_METHOD';
    public final static String ERR_BULKIFIED_NOT_SUPPORTED = 'ERR_BULKIFIED_NOT_SUPPORTED';
    
    /**
    * @description Serialization of t
    * @author ctixier | 10-10-2022 
    * @param logsToInsert Logs to insert asynchronously
    **/
    public static void insertExceptionsAsLogs(List<WrappedException> exceptionToInsertAsLogs, Boolean isFuture)
    {
        // ! PLEASE CUSTOMIZE THIS METHOD TO FIT THE NEEDS OF YOUR ORGANIZATION !
        // List<Log__c> logsToInsert = new List<Log__c>();
        // for(WrappedException e : exceptionToInsertAsLogs)
        // {
        //     logsToInsert.add(e.toErrorLog());
        // }

        // if (isFuture)
        // {
        //     insertLogsFuture(logsToInsert);
        // }
        // else
        // {
        //     insert logsToInsert;
        // }
    }
    
    // ! PLEASE CUSTOMIZE THIS METHOD TO FIT THE NEEDS OF YOUR ORGANIZATION !
    /**
    * @description Serialization of t
    * @author ctixier | 10-10-2022 
    * @param logsToInsert Logs to insert asynchronously
    ** /
    public static void insertLogsFuture(List<Log__c> logsToInsert)
    {
        insertLogsFuture(JSON.serialize(logsToInsert));
    }
    */


    // ! PLEASE CUSTOMIZE THIS METHOD TO FIT THE NEEDS OF YOUR ORGANIZATION !
    /**
    * @description insert a serialized List of Log__c records
    * @author ctixier | 10-10-2022 
    * @param serializedLstError 
    ** /
    @future
    private static void insertLogsFuture(String serializedLstError)
    {
        // List<Log__c> lstErr = (List<Log__c>)JSON.deserialize(serializedLstError, List<Log__c>.class);
        // insert lstErr;
    }*/
    
    // to manage Exceptions
    public class WrappedException extends Exception {
        public Exception sourceException;
        public String errorSource;

        /**
        * @description return the message of the source exception if it exists, otherwise return the current message
        * @author Simon Persenot | 15-05-2024 
        * @return String 
        **/
        public override String getMessage()
        {
            if (sourceException != null)
            {
                return sourceException.getMessage();
            }
            else {
                return super.getMessage();
            }
        }

        /**
        * @description return the stack trace of the source exception if it exists, otherwise return the current stack trace
        * @author Simon Persenot | 15-05-2024 
        * @return String 
        **/
        public override String getStackTraceString() {
            if (sourceException != null)
            {
                return sourceException.getStackTraceString();
            }
            else {
                return super.getStackTraceString();
            }
        }

        /**
        * @description Insert a new WrappedException with a message and a sourceException as parameters
        * @author Simon Persenot | 15-05-2024 
        * @param e 
        * @param source 
        **/
        public WrappedException(Exception e, String source) {
            sourceException = e;
            errorSource = source;
        }

        /**
        * @description Initialize a new WrappedException with a message and a source
        * @author Simon Persenot | 15-05-2024 
        * @param message 
        * @param source 
        **/
        public WrappedException(String message, String source) {
            this(message);
            errorSource = source;
        }
        
        // ! PLEASE CUSTOMIZE THIS METHOD TO FIT THE NEEDS OF YOUR ORGANIZATION !
        /**
        * @description do nothing at the moment, need to be customized to fit the needs of your organization
        * @author Simon Persenot | 15-05-2024 
        **/
        public void toErrorLog()
        {
            /* return new Log__c(
                Type__c = 'Error',
                Source__c = errorSource,
                ErrorMessage__c = this.getMessage(),
                ErrorDetails__c = this.getStackTraceString()
            ); */
        }
    }
    
    public virtual class DataValidationAbstract {
        /**
        * @description check that all target properties are set for the current class instance
        * @author ctixier | 09-26-2022 
        * @param mandatoryProperties list of property names that should exist in the current instance
        * @param emptyArrayValid if true, no exception will be thrown in case of an empty array being set for a mandatory property
        * @param className name of the current class, for error management purpose
        * @throws WrappedException exception if any property is missing
        **/
        public virtual void checkValidity(Set<String> mandatoryProperties, Boolean emptyArrayValid, String className)
        {
            Map<String,Object> thisMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(this));
            List<String> missingProperties = new List<String>();
            for(String prop : mandatoryProperties)
            {
                if(!thisMap.containsKey(prop) || thisMap.get(prop) == null || thisMap.get(prop) == '' || (!emptyArrayValid && String.valueOf(thisMap.get(prop)) == '()'))
                {
                    missingProperties.add(prop);
                }
            }
            if(!missingProperties.isEmpty())
            {
                throw new WrappedException(ERR_MISSING_PROPERTIES + ' - ' + className + ' (' + String.join(missingProperties, ', ') + ')',className);
            }
        }

        /**
        * @description default behavior of check validity (empty arrays are considered as non valid)
        * @author ctixier | 09-26-2022 
        * @param mandatoryProperties list of property names that should exist in the current instance
        * @param emptyArrayValid if true, no exception will be thrown in case of an empty array being set for a mandatory property
        * @throws Utils.WrappedException exception if any property is missing
        **/
        public virtual void checkValidity(Set<String> mandatoryProperties, String className)
        {
            this.checkValidity(mandatoryProperties, false, className);
        }
    }
}