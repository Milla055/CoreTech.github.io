/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.model;

import java.io.Serializable;
import java.util.Date;
import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;
import javax.xml.bind.annotation.XmlRootElement;

/**
 *
 * @author kamil
 */
@Entity
@Table(name = "product_notifications")
@XmlRootElement
@NamedQueries({
    @NamedQuery(name = "ProductNotifications.findAll", query = "SELECT p FROM ProductNotifications p"),
    @NamedQuery(name = "ProductNotifications.findById", query = "SELECT p FROM ProductNotifications p WHERE p.id = :id"),
    @NamedQuery(name = "ProductNotifications.findByUserEmail", query = "SELECT p FROM ProductNotifications p WHERE p.userEmail = :userEmail"),
    @NamedQuery(name = "ProductNotifications.findByProductId", query = "SELECT p FROM ProductNotifications p WHERE p.productId = :productId"),
    @NamedQuery(name = "ProductNotifications.findByNotified", query = "SELECT p FROM ProductNotifications p WHERE p.notified = :notified"),
    @NamedQuery(name = "ProductNotifications.findByCreatedAt", query = "SELECT p FROM ProductNotifications p WHERE p.createdAt = :createdAt"),
    @NamedQuery(name = "ProductNotifications.findByNotifiedAt", query = "SELECT p FROM ProductNotifications p WHERE p.notifiedAt = :notifiedAt")})
public class ProductNotifications implements Serializable {

    private static final long serialVersionUID = 1L;
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Basic(optional = false)
    @Column(name = "id")
    private Long id;
    @Basic(optional = false)
    @NotNull
    @Size(min = 1, max = 255)
    @Column(name = "user_email")
    private String userEmail;
    @Basic(optional = false)
    @NotNull
    @Column(name = "product_id")
    private long productId;
    @Column(name = "notified")
    private Boolean notified;
    @Basic(optional = false)
    @NotNull
    @Column(name = "created_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date createdAt;
    @Column(name = "notified_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date notifiedAt;

    public ProductNotifications() {
    }

    public ProductNotifications(Long id) {
        this.id = id;
    }

    public ProductNotifications(Long id, String userEmail, long productId, Date createdAt) {
        this.id = id;
        this.userEmail = userEmail;
        this.productId = productId;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getUserEmail() {
        return userEmail;
    }

    public void setUserEmail(String userEmail) {
        this.userEmail = userEmail;
    }

    public long getProductId() {
        return productId;
    }

    public void setProductId(long productId) {
        this.productId = productId;
    }

    public Boolean getNotified() {
        return notified;
    }

    public void setNotified(Boolean notified) {
        this.notified = notified;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }

    public Date getNotifiedAt() {
        return notifiedAt;
    }

    public void setNotifiedAt(Date notifiedAt) {
        this.notifiedAt = notifiedAt;
    }

    @Override
    public int hashCode() {
        int hash = 0;
        hash += (id != null ? id.hashCode() : 0);
        return hash;
    }

    @Override
    public boolean equals(Object object) {
        // TODO: Warning - this method won't work in the case the id fields are not set
        if (!(object instanceof ProductNotifications)) {
            return false;
        }
        ProductNotifications other = (ProductNotifications) object;
        if ((this.id == null && other.id != null) || (this.id != null && !this.id.equals(other.id))) {
            return false;
        }
        return true;
    }

    @Override
    public String toString() {
        return "com.mycompany.coretech3.model.ProductNotifications[ id=" + id + " ]";
    }
    
}
