package com.eazybytes.accounts.service.clients;

import com.eazybytes.accounts.dto.CardsDto;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

@FeignClient("cards") // service name in eureka server registry
public interface CardsFeignClient {

    @GetMapping(value = "/api/fetch", consumes = "application/json" )
    public ResponseEntity<CardsDto> fetchCardDetails(@RequestParam String mobileNumber);
}
