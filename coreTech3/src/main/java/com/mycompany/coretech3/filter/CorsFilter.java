/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.filter;

import java.io.IOException;
import javax.ws.rs.OPTIONS;
import javax.ws.rs.Path;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerResponseContext;
import javax.ws.rs.container.ContainerResponseFilter;
import javax.ws.rs.container.PreMatching;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.Provider;

@Provider

public class CorsFilter implements ContainerResponseFilter {

    @Override
    public void filter(ContainerRequestContext requestContext,
                       ContainerResponseContext responseContext) throws IOException {

        responseContext.getHeaders().add(
            "Access-Control-Allow-Origin", "http://localhost:4200"
        );

        responseContext.getHeaders().add(
            "Access-Control-Allow-Credentials", "true"
        );

        responseContext.getHeaders().add(
            "Access-Control-Allow-Headers",
            "Origin, Content-Type, Accept, Authorization"
        );

        responseContext.getHeaders().add(
            "Access-Control-Allow-Methods",
            "GET, POST, PUT, DELETE, OPTIONS"
        );
    }
    
}

