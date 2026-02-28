package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.security.JwtUtil;
import com.mycompany.coretech3.service.AddressService;
import io.jsonwebtoken.Claims;
import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

@Path("Addresses")
public class AddressController {

    @Inject
    private AddressService addressService;

    /**
     * Felhasználó összes címének lekérdezése
     * GET /api/Addresses/getUserAddresses
     * Header: Authorization: Bearer <token>
     */
    @GET
    @Path("getUserAddresses")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getUserAddresses(@HeaderParam("Authorization") String authHeader) {
        try {
            // Token validálása és userId kinyerése
            String token = authHeader.substring(7); // "Bearer " eltávolítása
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);

            // Service hívása
            JSONObject result = addressService.getUserAddresses(userId);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 401);
            error.put("message", "Érvénytelen token");
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

    /**
     * Új cím létrehozása
     * POST /api/Addresses/createAddress
     * Header: Authorization: Bearer <token>
     * Body: { "street": "...", "city": "...", "postalCode": "...", "country": "...", "isDefault": true/false }
     */
    @POST
    @Path("createAddress")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response createAddress(@HeaderParam("Authorization") String authHeader, String body) {
        try {
            // Token validálása és userId kinyerése
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);

            // Request body feldolgozása
            JSONObject obj = new JSONObject(body);
            String street = obj.getString("street");
            String city = obj.getString("city");
            String postalCode = obj.getString("postalCode");
            String country = obj.getString("country");
            boolean isDefault = obj.optBoolean("isDefault", false);

            // Validáció
            if (street == null || street.trim().isEmpty()) {
                JSONObject error = new JSONObject();
                error.put("status", "Error");
                error.put("statusCode", 400);
                error.put("message", "Az utca kötelező");
                return Response.status(400)
                        .entity(error.toString())
                        .type(MediaType.APPLICATION_JSON)
                        .build();
            }

            if (city == null || city.trim().isEmpty()) {
                JSONObject error = new JSONObject();
                error.put("status", "Error");
                error.put("statusCode", 400);
                error.put("message", "A város kötelező");
                return Response.status(400)
                        .entity(error.toString())
                        .type(MediaType.APPLICATION_JSON)
                        .build();
            }

            if (postalCode == null || postalCode.trim().isEmpty()) {
                JSONObject error = new JSONObject();
                error.put("status", "Error");
                error.put("statusCode", 400);
                error.put("message", "Az irányítószám kötelező");
                return Response.status(400)
                        .entity(error.toString())
                        .type(MediaType.APPLICATION_JSON)
                        .build();
            }

            if (country == null || country.trim().isEmpty()) {
                JSONObject error = new JSONObject();
                error.put("status", "Error");
                error.put("statusCode", 400);
                error.put("message", "Az ország kötelező");
                return Response.status(400)
                        .entity(error.toString())
                        .type(MediaType.APPLICATION_JSON)
                        .build();
            }

            // Service hívása
            JSONObject result = addressService.createAddress(userId, street, city, postalCode, country, isDefault);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 401);
            error.put("message", "Érvénytelen token vagy kérés");
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

    /**
     * Cím módosítása
     * PUT /api/Addresses/updateAddress/{addressId}
     * Header: Authorization: Bearer <token>
     * Body: { "street": "...", "city": "...", "postalCode": "...", "country": "...", "isDefault": true/false }
     */
    @PUT
    @Path("updateAddress/{addressId}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response updateAddress(
            @HeaderParam("Authorization") String authHeader,
            @PathParam("addressId") int addressId,
            String body) {
        try {
            // Token validálása és userId kinyerése
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);

            // Request body feldolgozása
            JSONObject obj = new JSONObject(body);
            String street = obj.getString("street");
            String city = obj.getString("city");
            String postalCode = obj.getString("postalCode");
            String country = obj.getString("country");
            boolean isDefault = obj.optBoolean("isDefault", false);

            // Validáció
            if (street == null || street.trim().isEmpty()) {
                JSONObject error = new JSONObject();
                error.put("status", "Error");
                error.put("statusCode", 400);
                error.put("message", "Az utca kötelező");
                return Response.status(400)
                        .entity(error.toString())
                        .type(MediaType.APPLICATION_JSON)
                        .build();
            }

            // Service hívása
            JSONObject result = addressService.updateAddress(addressId, userId, street, city, postalCode, country, isDefault);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 401);
            error.put("message", "Érvénytelen token vagy kérés");
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

    /**
     * Cím törlése
     * DELETE /api/Addresses/deleteAddress/{addressId}
     * Header: Authorization: Bearer <token>
     */
    @DELETE
    @Path("deleteAddress/{addressId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response deleteAddress(
            @HeaderParam("Authorization") String authHeader,
            @PathParam("addressId") int addressId) {
        try {
            // Token validálása és userId kinyerése
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);

            // Service hívása
            JSONObject result = addressService.deleteAddress(addressId, userId);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 401);
            error.put("message", "Érvénytelen token");
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

    /**
     * Alapértelmezett cím beállítása
     * PUT /api/Addresses/setDefaultAddress/{addressId}
     * Header: Authorization: Bearer <token>
     */
    @PUT
    @Path("setDefaultAddress/{addressId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response setDefaultAddress(
            @HeaderParam("Authorization") String authHeader,
            @PathParam("addressId") int addressId) {
        try {
            // Token validálása és userId kinyerése
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);

            // Service hívása
            JSONObject result = addressService.setDefaultAddress(addressId, userId);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 401);
            error.put("message", "Érvénytelen token");
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

    // ==================== ADMIN ENDPOINTOK ====================

    /**
     * Összes cím lekérdezése (ADMIN CSAK!)
     * GET /api/Addresses/getAllAddresses
     * Header: Authorization: Bearer <admin-token>
     */
    @GET
    @Path("getAllAddresses")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getAllAddresses(@HeaderParam("Authorization") String authHeader) {
        try {
            // Token validálása
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            String role = claims.get("role", String.class);

            // Csak admin hívhatja meg
            if (!"admin".equals(role)) {
                JSONObject error = new JSONObject();
                error.put("status", "Forbidden");
                error.put("statusCode", 403);
                error.put("message", "Nincs jogosultságod ehhez a művelethez");
                return Response.status(403)
                        .entity(error.toString())
                        .type(MediaType.APPLICATION_JSON)
                        .build();
            }

            // Service hívása
            JSONObject result = addressService.getAllAddresses();

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 401);
            error.put("message", "Érvénytelen token");
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

    /**
     * Egy konkrét cím lekérdezése ID alapján
     * GET /api/Addresses/getAddressById/{addressId}
     * Header: Authorization: Bearer <token>
     */
    @GET
    @Path("getAddressById/{addressId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getAddressById(
            @HeaderParam("Authorization") String authHeader,
            @PathParam("addressId") int addressId) {
        try {
            // Token validálása
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);

            // Service hívása
            JSONObject result = addressService.getAddressById(addressId);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 401);
            error.put("message", "Érvénytelen token");
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }
}