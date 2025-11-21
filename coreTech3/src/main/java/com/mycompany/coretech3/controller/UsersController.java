/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.service.EmailService;
import com.mycompany.coretech3.service.UsersService;
import javax.inject.Inject;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.PUT;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

/**
 *
 * @author kamil
 */
@Path("Users")
public class UsersController {

    @Inject   // ← CDI injektálja a UsersService EJB-t
    private UsersService usersService;

    @POST
    @Path("createUser")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response createUser(String body) {
        JSONObject obj = new JSONObject(body);

        String username = obj.getString("username");
        String email = obj.getString("email");
        String phone = obj.getString("phone");
        String password = obj.getString("password");
        String role = obj.has("role") ? obj.getString("role") : null;

        JSONObject result = usersService.createUser(username, email, phone, password, role);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    @PUT
    @Path("softDeleteUser")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response softDeleteUser(String body) {
        JSONObject obj = new JSONObject(body);

        int userId = obj.getInt("userId");

        JSONObject result = usersService.softDeleteUser(userId);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    @PUT
    @Path("updateUser")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response updateUser(String body) {
        JSONObject obj = new JSONObject(body);

        int userId = obj.getInt("userId");
        String email = obj.getString("email");
        String phone = obj.getString("phone");

        JSONObject result = usersService.updateUser(userId, email, phone);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    @PUT
    @Path("updatePassword")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response updatePassword(String body) {
        JSONObject obj = new JSONObject(body);

        int userId = obj.getInt("userId");
        String password = obj.getString("password");

        JSONObject result = usersService.updatePassword(userId, password);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    @GET
    @Path("getOrdersByUserId/{userId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getOrdersByUserId(@PathParam("userId") int userId) {

        JSONObject result = usersService.getOrdersByUserId(userId);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    @POST
    @Path("login")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response login(String body) {
        System.out.println("BODY RAW: " + body);

        JSONObject obj = new JSONObject(body);

        String email = obj.getString("email");
        String password = obj.getString("password");

        JSONObject result = usersService.login(email, password);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    @GET
    @Path("testEmail")
    @Produces(MediaType.APPLICATION_JSON)
    public Response testEmail() {

        EmailService.sendEmail(
                "valaki@gmail.com",
                "Teszt email",
                "<h1>Hello Milla!</h1><p>Működik a Gmail smtp!</p>"
        );

        return Response.ok("{\"status\":\"email sent\"}").build();
    }

}
