package nl.nightcrowler.spring.springsslclientauth;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(path = "api/v1/ssl")
public class TestController {

    @GetMapping(value = "/check")
    public String checkConnection() throws InterruptedException {
        return "OK";
    }
}
