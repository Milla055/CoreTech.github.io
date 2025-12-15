package com.mycompany.coretech3.controller;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
/**
 *
 * @author kamil
 */
import com.mycompany.coretech3.service.AdminUsersService;
import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONArray;
import org.json.JSONObject;

@Stateless
@Path("admin/users")
@Produces(MediaType.APPLICATION_JSON)
public class AdminUsersController {

    @Inject
    private AdminUsersService adminUsersService;

    // ================= TEST =================
    @GET
    @Path("test")
    public Response test() {
        return Response.ok("{\"msg\":\"admin users controller OK\"}").build();
    }

    // ================= GET ALL USERS =================
    @GET
    public Response getAllUsers() {

        JSONArray users = adminUsersService.getAllUsersAdmin();

        JSONObject resp = new JSONObject();
        resp.put("status", "Success");
        resp.put("statusCode", 200);
        resp.put("users", users);

        return Response.ok(resp.toString()).build();
    }

    // ================= GET USER BY ID =================
    @GET
    @Path("{userId}")
    public Response getUserById(
            @PathParam("userId") int userId) {

        JSONObject result = adminUsersService.getUserAdmin(userId);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }

    // ================= UPDATE USER ROLE =================
    @PUT
    @Path("role")
    @Consumes(MediaType.APPLICATION_JSON)
    public Response updateRole(String body) {

        JSONObject obj = new JSONObject(body);
        int userId = obj.getInt("userId");
        String newRole = obj.getString("newRole");

        JSONObject result =
                adminUsersService.updateUserRole(userId, newRole);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }

    // ================= SOFT DELETE USER =================
    @PUT
    @Path("delete/{userId}")
    public Response softDeleteUser(
            @PathParam("userId") int userId) {

        JSONObject result =
                adminUsersService.softDeleteUser(userId);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }

    // ================= GET ADMINS =================
    @GET
    @Path("filter/admin")
    public Response getAdmins() {

        JSONArray users = adminUsersService.getAdmins();

        JSONObject resp = new JSONObject();
        resp.put("status", "Success");
        resp.put("statusCode", 200);
        resp.put("admins", users);

        return Response.ok(resp.toString()).build();
    }

    // ================= GET CUSTOMERS =================
    @GET
    @Path("filter/customer")
    public Response getCustomers() {

        JSONArray users = adminUsersService.getCustomers();

        JSONObject resp = new JSONObject();
        resp.put("status", "Success");
        resp.put("statusCode", 200);
        resp.put("customers", users);

        return Response.ok(resp.toString()).build();
    }
}