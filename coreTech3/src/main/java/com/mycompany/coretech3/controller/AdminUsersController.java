package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.service.AdminUsersService;
import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

@Path("admin/users")
@Produces(MediaType.APPLICATION_JSON)
public class AdminUsersController {

    @Inject
    private AdminUsersService adminUsersService;

    @GET
    @Path("test")
    public Response test() {
        System.out.println("=== ADMIN USERS TEST ENDPOINT CALLED ===");
        JSONObject resp = new JSONObject();
        resp.put("message", "Admin users endpoint is working!");
        resp.put("status", 200);
        return Response.ok(resp.toString()).build();
    }

    @GET
    @Path("getAllUsers")
    public Response getAllUsers() {
        System.out.println("=== GET ALL USERS CALLED ===");
        JSONObject result = adminUsersService.getAllUsersAdmin();
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    @GET
    @Path("{userId}")
    public Response getUserById(@PathParam("userId") int userId) {
        System.out.println("=== GET USER BY ID CALLED: " + userId + " ===");
        JSONObject result = adminUsersService.getUserById(userId);
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    @GET
    @Path("filter/admins")
    public Response getAdmins() {
        System.out.println("=== GET ADMINS CALLED ===");
        JSONObject result = adminUsersService.getAdmins();
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    @GET
    @Path("filter/customers")
    public Response getCustomers() {
        System.out.println("=== GET CUSTOMERS CALLED ===");
        JSONObject result = adminUsersService.getCustomers();
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    @PUT
    @Path("role")
    @Consumes(MediaType.APPLICATION_JSON)
    public Response updateUserRole(String body) {
        System.out.println("=== UPDATE USER ROLE CALLED ===");
        try {
            JSONObject obj = new JSONObject(body);
            int userId = obj.getInt("userId");
            String newRole = obj.getString("newRole");

            JSONObject result = adminUsersService.updateUserRole(userId, newRole);
            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "InvalidRequest");
            error.put("statusCode", 400);
            error.put("message", "Invalid request body: " + e.getMessage());
            return Response.status(400)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }
    @PUT
@Path("delete/{userId}")
public Response softDeleteUser(@PathParam("userId") int userId) {
    System.out.println("=== SOFT DELETE USER CALLED: " + userId + " ===");
    JSONObject result = adminUsersService.softDeleteUser(userId);
    return Response.status(result.getInt("statusCode"))
            .entity(result.toString())
            .type(MediaType.APPLICATION_JSON)
            .build();
}
}
