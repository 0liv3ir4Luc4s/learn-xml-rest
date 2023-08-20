public class Sabao {
    public class SabaoModel {
        private Integer num;
        private String numberToWords;
        
        public SabaoModel(Integer num) {
            this.num = num;
        }

        public String getNumberToWords() {
            return this.numberToWords;
        }
    
        public Dom.Document parseRequest() {
            Dom.Document doc = new Dom.Document();
            Dom.XmlNode envelope = doc.createRootElement(
                                        'Envelope', 
                                        'http://schemas.xmlsoap.org/soap/envelope/',
                                        'soap');
    
            Dom.XmlNode body = envelope.addChildElement(
                                        'Body',
                                        'http://schemas.xmlsoap.org/soap/envelope/',
                                        'soap');
    
            Dom.XmlNode numberToWords = body.addChildElement(
                                        'NumberToWords',
                                        'http://www.dataaccess.com/webservicesserver/',
                                        '');
    
            Dom.XmlNode ubiNum = numberToWords.addChildElement('ubiNum',
                                        null, 
                                        null);
    
            ubiNum.addTextNode(String.valueOf(this.num));
            
            return doc;
        }

        public void parseResponse(Dom.Document response) {
            this.numberToWords = response.getRootElement()
                                .getChildElement(
                                    'Body',
                                    'http://schemas.xmlsoap.org/soap/envelope/')
                                    .getChildElement(
                                        'NumberToWordsResponse',
                                        'http://www.dataaccess.com/webservicesserver/')
                                        .getChildElement(
                                            'NumberToWordsResult',
                                            'http://www.dataaccess.com/webservicesserver/')
                                            .getText();
        }
    }

    public static String request() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://www.dataaccess.com/webservicesserver/NumberConversion.wso');
        req.setMethod('POST');
  
        req.setHeader('Content-Type', 'text/xml;charset=UTF-8');

        SabaoModel model = new SabaoModel(5);
        req.setBodyDocument(model.parseRequest());

        Http http = new Http();
        HTTPResponse res = http.send(req);
        model.parseResponse(res.getBodyDocument());

        return model.getNumberToWords();
    }

}