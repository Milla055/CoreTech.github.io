/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.service;

/**
 *
 * @author kamil
 */
import com.mycompany.coretech3.model.Users;
import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import org.json.JSONArray;
import org.json.JSONObject;

@Stateless
public class AdminUsersService {

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    public JSONArray getAllUsersAdmin() {
        JSONArray arr = new JSONArray();

        try {
            List<Users> users = em.createQuery(
                    "SELECT u FROM Users u ORDER BY u.id",
                    Users.class
            ).getResultList();

            for (Users u : users) {
                JSONObject obj = new JSONObject();
                obj.put("id", u.getId());
                obj.put("username", u.getUsername());
                obj.put("email", u.getEmail());
                obj.put("phone", u.getPhone());
                obj.put("role", u.getRole());
                obj.put("created_at", u.getCreatedAt());
                obj.put("is_deleted", u.getIsDeleted());
                obj.put("deleted_at", u.getDeletedAt());
                arr.put(obj);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return arr;
    }

    public JSONObject getUserAdmin(int userId) {
        JSONObject resp = new JSONObject();

        try {
            Users u = em.find(Users.class, userId);

            if (u == null) {
                resp.put("status", "UserNotFound");
                resp.put("statusCode", 404);
                return resp;
            }

            JSONObject obj = new JSONObject();
            obj.put("id", u.getId());
            obj.put("username", u.getUsername());
            obj.put("email", u.getEmail());
            obj.put("phone", u.getPhone());
            obj.put("role", u.getRole());
            obj.put("created_at", u.getCreatedAt());
            obj.put("is_deleted", u.getIsDeleted());
            obj.put("deleted_at", u.getDeletedAt());

            resp.put("user", obj);
            resp.put("status", "Success");
            resp.put("statusCode", 200);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
        }

        return resp;
    }

    public JSONObject updateUserRole(int userId, String newRole) {
        JSONObject resp = new JSONObject();

        try {
            Users u = em.find(Users.class, userId);

            if (u == null) {
                resp.put("status", "UserNotFound");
                resp.put("statusCode", 404);
                return resp;
            }

            u.setRole(newRole);
            em.merge(u);

            resp.put("status", "RoleUpdated");
            resp.put("statusCode", 200);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
        }

        return resp;
    }

    public JSONObject softDeleteUser(int userId) {
        JSONObject resp = new JSONObject();

        try {
            Users u = em.find(Users.class, userId);

            if (u == null) {
                resp.put("status", "UserNotFound");
                resp.put("statusCode", 404);
                return resp;
            }

            u.setIsDeleted(true);
            u.setDeletedAt(new java.util.Date());
            em.merge(u);

            resp.put("status", "UserSoftDeleted");
            resp.put("statusCode", 200);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
        }

        return resp;
    }
}
