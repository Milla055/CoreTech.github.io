/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.service.NewsletterService;
import javax.ejb.EJB;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

@Path("/newsletter")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class NewsletterController {

    @EJB
    private NewsletterService newsletterService;

    @POST
    @Path("/subscribe")
    public Response subscribe(String body) {
        JSONObject input = new JSONObject(body);
        String email = input.getString("email");

        JSONObject result = newsletterService.subscribeToNewsletter(email);
        int statusCode = result.getInt("statusCode");

        return Response.status(statusCode).entity(result.toString()).build();
    }

    @POST
    @Path("/send")
    public Response sendNewsletter(String body) {
        JSONObject input = new JSONObject(body);
        String type = input.getString("type");

        JSONObject result = newsletterService.sendNewsletter(type);
        int statusCode = result.getInt("statusCode");

        return Response.status(statusCode).entity(result.toString()).build();
    }

    
    @GET
    @Path("/all")
    public Response getAllNewsletters() {
        JSONObject result = newsletterService.getAllNewsletters();
        int statusCode = result.getInt("statusCode");

        return Response.status(statusCode).entity(result.toString()).build();
    }

    
    @GET
    @Path("/subscribers")
    public Response getSubscribers() {
        JSONObject result = newsletterService.getSubscribers();
        int statusCode = result.getInt("statusCode");

        return Response.status(statusCode).entity(result.toString()).build();
    }
}
