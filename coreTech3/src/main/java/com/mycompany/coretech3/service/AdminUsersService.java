package com.mycompany.coretech3.service;

import com.mycompany.coretech3.model.Users;
import java.util.Date;
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

    public JSONArray getAdmins() {
        List<Object[]> rows = em.createNativeQuery(
                "SELECT id, username, email, phone, role, created_at "
                + "FROM users "
                + "WHERE role = 'admin' AND (is_deleted IS NULL OR is_deleted = 0) "
                + "ORDER BY created_at DESC"
        ).getResultList();

        JSONArray arr = new JSONArray();

        for (Object[] row : rows) {
            JSONObject obj = new JSONObject();
            obj.put("id", row[0]);
            obj.put("username", row[1]);
            obj.put("email", row[2]);
            obj.put("phone", row[3]);
            obj.put("role", row[4]);
            obj.put("createdAt", row[5]);
            arr.put(obj);
        }

        return arr;
    }

    public JSONArray getCustomers() {
        List<Object[]> rows = em.createNativeQuery(
                "SELECT id, username, email, phone, role, created_at "
                + "FROM users "
                + "WHERE role = 'customer' AND (is_deleted IS NULL OR is_deleted = 0) "
                + "ORDER BY created_at DESC"
        ).getResultList();

        JSONArray arr = new JSONArray();

        for (Object[] row : rows) {
            JSONObject obj = new JSONObject();
            obj.put("id", row[0]);
            obj.put("username", row[1]);
            obj.put("email", row[2]);
            obj.put("phone", row[3]);
            obj.put("role", row[4]);
            obj.put("createdAt", row[5]);
            arr.put(obj);
        }

        return arr;
    }

}