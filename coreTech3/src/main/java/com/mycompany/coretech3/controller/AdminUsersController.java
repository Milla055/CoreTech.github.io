package com.mycompany.coretech3.controller;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
/**
 *
 * @author kamil
 */
import com.mycompany.coretech3.model.Users;
import com.mycompany.coretech3.service.AdminUsersService;
import javax.inject.Inject;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONArray;
import org.json.JSONObject;

@Stateless
@Path("admin/users")
public class AdminUsersController {

    @Inject
    private AdminUsersService adminUsersService;  // ← EZ AZ ÚJ

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    private boolean isAdmin(int adminId) {
        Users admin = em.find(Users.class, adminId);
        return admin != null && "admin".equals(admin.getRole());
    }

    @GET
    @Path("getAll/{adminId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getAllUsers(@PathParam("adminId") int adminId) {

        if (!isAdmin(adminId)) {
            return Response.status(403)
                    .entity("{\"error\":\"Forbidden - Admin only\"}")
                    .build();
        }

        JSONArray users = adminUsersService.getAllUsersAdmin();

        JSONObject resp = new JSONObject();
        resp.put("status", "Success");
        resp.put("statusCode", 200);
        resp.put("users", users);

        return Response.ok(resp.toString()).build();
    }

    @GET
    @Path("getById/{adminId}/{userId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getUserById(
            @PathParam("adminId") int adminId,
            @PathParam("userId") int userId) {

        if (!isAdmin(adminId)) {
            return Response.status(403)
                    .entity("{\"error\":\"Forbidden - Admin only\"}")
                    .build();
        }

        JSONObject result = adminUsersService.getUserAdmin(userId);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }

    @PUT
    @Path("role/{adminId}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response updateRole(
            @PathParam("adminId") int adminId,
            String body) {

        if (!isAdmin(adminId)) {
            return Response.status(403)
                    .entity("{\"error\":\"Forbidden - Admin only\"}")
                    .build();
        }

        JSONObject obj = new JSONObject(body);
        int userId = obj.getInt("userId");
        String newRole = obj.getString("newRole");

        JSONObject result = adminUsersService.updateUserRole(userId, newRole);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }

    @DELETE
    @Path("delete/{adminId}/{userId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response softDeleteUser(
            @PathParam("adminId") int adminId,
            @PathParam("userId") int userId) {

        if (!isAdmin(adminId)) {
            return Response.status(403)
                    .entity("{\"error\":\"Forbidden - Admin only\"}")
                    .build();
        }

        JSONObject result = adminUsersService.softDeleteUser(userId);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }

}
