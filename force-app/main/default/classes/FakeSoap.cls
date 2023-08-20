/**
 * @description Demonstrates how to make an opinionated REST callout.
 * This class utilizes the custom RestClient from the Shared Code group.
 * @group Integration Recipes
 * @see RestClient
 */
public with sharing class CalloutRecipes extends RestClient {
    /**
     * @description Internal custom exception class
     */
    public class CalloutRecipesException extends Exception {
    }

    /**
     * @description Constructor accepting a named credential.
     * @param namedCredential name of the Named Credential to use
     */
    public CalloutRecipes(String namedCredential) {
        super(namedCredential);
    }

    /**
     * @description Demonstrates how to make a raw HTTP request. This method
     * demonstrates how to use the Http, HttpRequest and HttpResponse objects to
     * construct a single get reuqest. The other methods in this class
     * demonstrate the use of an intelligent abstraction layer - RestClient.cls
     * - to make sending Http Requests easier, easier to test, and less error
     * prone.
     * @return String
     * @example
     * System.debug(CalloutRecipes.rawCallout());
     **/
    public static String rawCallout() {
        // the HTTP instance is used to actually make the request.
        Http http = new Http();

        HttpRequest request = new HttpRequest();
        request.setEndpoint(
            'https://mockbin.org/bin/24d66572-81e6-46bd-986b-610f1b5c4e00/view'
        );
        request.setMethod('GET');

        HttpResponse response = http.send(request);

        if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
            return response.getBody();
        }

        throw new CalloutRecipesException(
            'Did not get a success response from the callout. Details, Status Code: ' +
                response.getStatusCode() +
                ' status message: ' +
                response.getStatus()
        );
    }

    /**
     * @description Now that we have demonstrated how to callout to an endpoint,
     * lets take a look at what else we can do with the response. When calling
     * out to an external endpoint, the data may not always be in a format that
     * can be directly deserialised into a Salesforce Object. If your callout
     * returns untyped JSON, you can deserialize this into a Map<String, Object>
     * by using a deserializeUntyped method to convert the string.
     * @return Map<String, Object>
     * @example
     * System.debug(CalloutRecipes.httpCalloutWithUntypedResponse());
     */
    public Map<String, Object> httpCalloutWithUntypedResponse() {
        // This Recipe also demonstrates how to do a one-off override of the
        // Named Credential It stores the original named credential name,
        // resets the active named credential and before returning, ensures the
        // named credential is reset.
        String originalNamedCredential = namedCredentialName;
        namedCredentialName = 'ExternalEndpoint';
        HttpResponse response = get('fakeEndpoint/');
        try {
            String responseBody = response.getBody();
            // Attempt to deserialize the untyped response into a
            // Map<String,Object>
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
                responseBody
            );
            // Reset the named credential for this class back to the original
            namedCredentialName = originalNamedCredential;
            return responseMap;
        } catch (JSONException e) {
            // If the deseralization fails, we can debug it using a JSON
            // Exception
            System.debug(
                LoggingLevel.INFO,
                'Failed to serialize the body. Error is: ' + e.getMessage()
            );
            // Reset the named credential for this class back to the original
            namedCredentialName = originalNamedCredential;
            // return null to the method that initiated the callout
            return null;
        }
    }

    /**
     * @description As seen in the httpCalloutWithUntypedResponse method, we
     * don't always get a perfect datastructure back from our callout. In this
     * case, we have received and account and it's contacts that need to be
     * inserted into Salesforce. Check out the Test class for an example of an
     * untyped data structure.
     * @param untypedResponse the untyped JSON response that we received from
     * our previous callout
     * @example
     * CalloutRecipes.insertAccountAndContactsFromUntypedResponse(CalloutRecipes_Tests.goodUntypedJSON)
     */
    public void insertAccountAndContactsFromUntypedResponse(
        String untypedResponse
    ) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
            untypedResponse
        );
        // Instantiate a List<SObject> to hold our data
        List<SObject> dataToInsert = new List<SObject>();
        // Create an temporary reference to associate the contacts and accounts,
        // here we will use an ExternalId__c field
        Account accountReference = new Account();
        // We can use a .get('fieldName') to extract data from the map
        accountReference.ExternalSalesforceId__c = responseMap.get('Id')
            .toString();
        // We can then instantiate a new Account and populate it with data using
        // the .get('fieldName') again
        Account newAccount = new Account();
        newAccount.ExternalSalesforceId__c = responseMap.get('Id').toString();
        newAccount.Name = responseMap.get('Name').toString();
        newAccount.Website = responseMap.get('Website').toString();
        // Add the account to our List<SObject> for us to insert
        dataToInsert.add(newAccount);
        // We can now create a list of contact from our response body
        List<Object> contactList = (List<Object>) responseMap.get('Contacts');
        // Because we may have multiple contacts per account, we can loop
        // through the list and assign the values from the map
        for (Integer i = 0; i < contactList.size(); i++) {
            Map<String, Object> singleContact = (Map<String, Object>) contactList[
                i
            ];
            Contact newContact = new Contact();
            newContact.FirstName = singleContact.get('FirstName').toString();
            newContact.LastName = singleContact.get('LastName').toString();
            newContact.Email = singleContact.get('Email').toString();
            // Assign the account referene to the Contact.Account field using
            // our external Id that we set earlier
            newContact.Account = accountReference;
            // We can add the contact to our List<SObject> along with the
            // account
            dataToInsert.add(newContact);
        }
        // Now that our data is populated into the dataToInsert variable, we can
        // use a Database.insert to insert the generaic SObject list.
        // This will preserve the contacts relationship to the accounts.
        List<Database.SaveResult> saveResults = Database.insert(dataToInsert);
        // Create a list of Success & Failures for verification of the result
        List<Id> successes = new List<Id>();
        List<Id> failures = new List<Id>();
        for (Database.SaveResult sr : saveResults) {
            if (sr.isSuccess()) {
                successes.add(sr.id);
            } else {
                failures.add(sr.id);
            }
        }
        System.debug(LoggingLevel.INFO, 'Successes: ' + successes);
        System.debug(LoggingLevel.INFO, 'Failures: ' + failures);
    }
}