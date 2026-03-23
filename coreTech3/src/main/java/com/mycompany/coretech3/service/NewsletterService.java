
package com.mycompany.coretech3.service;

import com.mycompany.coretech3.model.Users;
import com.mycompany.coretech3.util.EmailTemplateLoader;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.TypedQuery;
import java.util.List;
import javax.persistence.Query;
import org.json.JSONArray;
import org.json.JSONObject;

@Stateless
public class NewsletterService {
    
    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;
    
    public JSONObject subscribeToNewsletter(String email) {
    JSONObject resp = new JSONObject();
    
    try {
        // 1) Find user by email
        TypedQuery<Users> query = em.createQuery(
            "SELECT u FROM Users u WHERE u.email = :email", Users.class);
        query.setParameter("email", email);
        
        List<Users> users = query.getResultList();
        
        if (users.isEmpty()) {
            resp.put("status", "UserNotFound");
            resp.put("statusCode", 404);
            resp.put("message", "User not found with this email");
            return resp;
        }
        
        Users user = users.get(0);
        
        // 2) Check if already subscribed
        if (Boolean.TRUE.equals(user.getIsSubscripted())) {
            resp.put("status", "AlreadySubscribed");
            resp.put("statusCode", 400);
            resp.put("message", "User is already subscribed to newsletter");
            return resp;
        }
        
        // 3) Update ONLY isSubscripted field - bypass validation!
        Query updateQuery = em.createQuery(
            "UPDATE Users u SET u.isSubscripted = true WHERE u.id = :userId"
        );
        updateQuery.setParameter("userId", user.getId());
        updateQuery.executeUpdate();
        
        // 4) Send welcome email
        String username = user.getUsername();
        String template = EmailTemplateLoader.loadTemplate("newsletter_welcome.html");
        
        if (template != null) {
            template = template.replace("{{username}}", username);
            EmailService.sendEmail(
                email,
                "Welcome to CoreTech Newsletter!",
                template
            );
        }
        
        resp.put("status", "Subscribed");
        resp.put("statusCode", 200);
        resp.put("message", "Successfully subscribed to newsletter");
        resp.put("userId", user.getId());
        
    } catch (Exception e) {
        e.printStackTrace();
        resp.put("status", "DatabaseError");
        resp.put("statusCode", 500);
        resp.put("message", "Error subscribing to newsletter: " + e.getMessage());
    }
    
    return resp;
}
    
    // =====================================================
    // 2) SEND NEWSLETTER - típus szerint
    // =====================================================
    public JSONObject sendNewsletter(String type) {
        JSONObject resp = new JSONObject();
        
        // Validate newsletter type
        String templateFile = getTemplateFileName(type);
        if (templateFile == null) {
            resp.put("status", "InvalidType");
            resp.put("statusCode", 400);
            resp.put("message", "Invalid newsletter type. Available: new_arrivals, summer_sale, vip_exclusive");
            return resp;
        }
        
        try {
            // 1) Get all subscribed users (Boolean TRUE és nem deleted)
            TypedQuery<Users> query = em.createQuery(
                "SELECT u FROM Users u WHERE u.isSubscripted = true AND (u.isDeleted = false OR u.isDeleted IS NULL)", 
                Users.class
            );
            
            List<Users> subscribers = query.getResultList();
            
            if (subscribers.isEmpty()) {
                resp.put("status", "NoSubscribers");
                resp.put("statusCode", 404);
                resp.put("message", "No subscribed users found");
                return resp;
            }
            
            // 2) Load email template
            String template = EmailTemplateLoader.loadTemplate(templateFile);
            if (template == null) {
                resp.put("status", "TemplateError");
                resp.put("statusCode", 500);
                resp.put("message", "Failed to load email template");
                return resp;
            }
            
            String subject = getEmailSubject(type);
            int sentCount = 0;
            int failedCount = 0;
            
            // 3) Send to all subscribers
            for (Users user : subscribers) {
                try {
                    String personalizedTemplate = template.replace("{{username}}", user.getUsername());
                    
                    EmailService.sendEmail(
                        user.getEmail(),
                        subject,
                        personalizedTemplate
                    );
                    
                    sentCount++;
                    
                } catch (Exception e) {
                    System.err.println("Failed to send newsletter to " + user.getEmail() + ": " + e.getMessage());
                    failedCount++;
                }
            }
            
            resp.put("status", "NewsletterSent");
            resp.put("statusCode", 200);
            resp.put("message", "Newsletter sent successfully");
            resp.put("type", type);
            resp.put("totalSubscribers", subscribers.size());
            resp.put("sentSuccessfully", sentCount);
            resp.put("failed", failedCount);
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", "Error sending newsletter: " + e.getMessage());
        }
        
        return resp;
    }
    
    // =====================================================
    // 3) GET ALL NEWSLETTER TYPES
    // =====================================================
    public JSONObject getAllNewsletters() {
        JSONObject resp = new JSONObject();
        JSONArray newsletters = new JSONArray();
        
        newsletters.put(new JSONObject()
            .put("type", "welcome")
            .put("name", "Welcome Email")
            .put("description", "Sent automatically when user subscribes"));
        
        newsletters.put(new JSONObject()
            .put("type", "new_arrivals")
            .put("name", "New Arrivals")
            .put("description", "Showcase latest PC components and products"));
        
        newsletters.put(new JSONObject()
            .put("type", "summer_sale")
            .put("name", "Summer Sale")
            .put("description", "Seasonal promotion with special discounts"));
        
        newsletters.put(new JSONObject()
            .put("type", "vip_exclusive")
            .put("name", "VIP Exclusive")
            .put("description", "Premium offers for valued customers"));
        
        resp.put("status", "Success");
        resp.put("statusCode", 200);
        resp.put("newsletters", newsletters);
        
        return resp;
    }
    
    // =====================================================
    // 4) GET ALL SUBSCRIBERS
    // =====================================================
    public JSONObject getSubscribers() {
        JSONObject resp = new JSONObject();
        
        try {
            TypedQuery<Users> query = em.createQuery(
                "SELECT u FROM Users u WHERE u.isSubscripted = true AND (u.isDeleted = false OR u.isDeleted IS NULL) ORDER BY u.createdAt DESC",
                Users.class
            );
            
            List<Users> subscribers = query.getResultList();
            JSONArray subscribersArray = new JSONArray();
            
            for (Users user : subscribers) {
                JSONObject userObj = new JSONObject();
                userObj.put("id", user.getId());
                userObj.put("username", user.getUsername());
                userObj.put("email", user.getEmail());
                userObj.put("subscribedAt", user.getCreatedAt().toString());
                subscribersArray.put(userObj);
            }
            
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("totalSubscribers", subscribers.size());
            resp.put("subscribers", subscribersArray);
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", "Error fetching subscribers: " + e.getMessage());
        }
        
        return resp;
    }
    
    // =====================================================
    // HELPER METHODS
    // =====================================================
    
    private String getTemplateFileName(String type) {
        switch (type) {
            case "new_arrivals":
                return "newsletter_new_arrivals.html";
            case "summer_sale":
                return "newsletter_summer_sale.html";
            case "vip_exclusive":
                return "newsletter_vip_exclusive.html";
            default:
                return null;
        }
    }
    
    private String getEmailSubject(String type) {
        switch (type) {
            case "new_arrivals":
                return "🚀 New PC Components Just Arrived!";
            case "summer_sale":
                return "☀️ Summer Sale - Up to 50% OFF!";
            case "vip_exclusive":
                return "⭐ VIP Exclusive Offer Just For You";
            default:
                return "CoreTech Newsletter";
        }
    }
}
