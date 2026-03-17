/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.model;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;
import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Lob;
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
@Table(name = "pc_configurations")
@XmlRootElement
@NamedQueries({
    @NamedQuery(name = "PcConfigurations.findAll", query = "SELECT p FROM PcConfigurations p"),
    @NamedQuery(name = "PcConfigurations.findById", query = "SELECT p FROM PcConfigurations p WHERE p.id = :id"),
    @NamedQuery(name = "PcConfigurations.findByName", query = "SELECT p FROM PcConfigurations p WHERE p.name = :name"),
    @NamedQuery(name = "PcConfigurations.findByBudgetMin", query = "SELECT p FROM PcConfigurations p WHERE p.budgetMin = :budgetMin"),
    @NamedQuery(name = "PcConfigurations.findByBudgetMax", query = "SELECT p FROM PcConfigurations p WHERE p.budgetMax = :budgetMax"),
    @NamedQuery(name = "PcConfigurations.findByUseCase", query = "SELECT p FROM PcConfigurations p WHERE p.useCase = :useCase"),
    @NamedQuery(name = "PcConfigurations.findByGameTypes", query = "SELECT p FROM PcConfigurations p WHERE p.gameTypes = :gameTypes"),
    @NamedQuery(name = "PcConfigurations.findByRequirementLevel", query = "SELECT p FROM PcConfigurations p WHERE p.requirementLevel = :requirementLevel"),
    @NamedQuery(name = "PcConfigurations.findByTotalPrice", query = "SELECT p FROM PcConfigurations p WHERE p.totalPrice = :totalPrice"),
    @NamedQuery(name = "PcConfigurations.findByIsFeatured", query = "SELECT p FROM PcConfigurations p WHERE p.isFeatured = :isFeatured"),
    @NamedQuery(name = "PcConfigurations.findByCreatedAt", query = "SELECT p FROM PcConfigurations p WHERE p.createdAt = :createdAt"),
    @NamedQuery(name = "PcConfigurations.findByIsDeleted", query = "SELECT p FROM PcConfigurations p WHERE p.isDeleted = :isDeleted"),
    @NamedQuery(name = "PcConfigurations.findByDeletedAt", query = "SELECT p FROM PcConfigurations p WHERE p.deletedAt = :deletedAt")})
public class PcConfigurations implements Serializable {

    private static final long serialVersionUID = 1L;
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Basic(optional = false)
    @Column(name = "id")
    private Long id;
    @Basic(optional = false)
    @NotNull
    @Size(min = 1, max = 255)
    @Column(name = "name")
    private String name;
    @Lob
    @Size(max = 65535)
    @Column(name = "description")
    private String description;
    @Basic(optional = false)
    @NotNull
    @Column(name = "budget_min")
    private int budgetMin;
    @Basic(optional = false)
    @NotNull
    @Column(name = "budget_max")
    private int budgetMax;
    @Basic(optional = false)
    @NotNull
    @Size(min = 1, max = 13)
    @Column(name = "use_case")
    private String useCase;
    @Size(max = 255)
    @Column(name = "game_types")
    private String gameTypes;
    @Basic(optional = false)
    @NotNull
    @Column(name = "requirement_level")
    private short requirementLevel;
    // @Max(value=?)  @Min(value=?)//if you know range of your decimal fields consider using these annotations to enforce field validation
    @Basic(optional = false)
    @NotNull
    @Column(name = "total_price")
    private BigDecimal totalPrice;
    @Column(name = "is_featured")
    private Boolean isFeatured;
    @Basic(optional = false)
    @NotNull
    @Column(name = "created_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date createdAt;
    @Column(name = "is_deleted")
    private Boolean isDeleted;
    @Column(name = "deleted_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date deletedAt;

    public PcConfigurations() {
    }

    public PcConfigurations(Long id) {
        this.id = id;
    }

    public PcConfigurations(Long id, String name, int budgetMin, int budgetMax, String useCase, short requirementLevel, BigDecimal totalPrice, Date createdAt) {
        this.id = id;
        this.name = name;
        this.budgetMin = budgetMin;
        this.budgetMax = budgetMax;
        this.useCase = useCase;
        this.requirementLevel = requirementLevel;
        this.totalPrice = totalPrice;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public int getBudgetMin() {
        return budgetMin;
    }

    public void setBudgetMin(int budgetMin) {
        this.budgetMin = budgetMin;
    }

    public int getBudgetMax() {
        return budgetMax;
    }

    public void setBudgetMax(int budgetMax) {
        this.budgetMax = budgetMax;
    }

    public String getUseCase() {
        return useCase;
    }

    public void setUseCase(String useCase) {
        this.useCase = useCase;
    }

    public String getGameTypes() {
        return gameTypes;
    }

    public void setGameTypes(String gameTypes) {
        this.gameTypes = gameTypes;
    }

    public short getRequirementLevel() {
        return requirementLevel;
    }

    public void setRequirementLevel(short requirementLevel) {
        this.requirementLevel = requirementLevel;
    }

    public BigDecimal getTotalPrice() {
        return totalPrice;
    }

    public void setTotalPrice(BigDecimal totalPrice) {
        this.totalPrice = totalPrice;
    }

    public Boolean getIsFeatured() {
        return isFeatured;
    }

    public void setIsFeatured(Boolean isFeatured) {
        this.isFeatured = isFeatured;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }

    public Boolean getIsDeleted() {
        return isDeleted;
    }

    public void setIsDeleted(Boolean isDeleted) {
        this.isDeleted = isDeleted;
    }

    public Date getDeletedAt() {
        return deletedAt;
    }

    public void setDeletedAt(Date deletedAt) {
        this.deletedAt = deletedAt;
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
        if (!(object instanceof PcConfigurations)) {
            return false;
        }
        PcConfigurations other = (PcConfigurations) object;
        if ((this.id == null && other.id != null) || (this.id != null && !this.id.equals(other.id))) {
            return false;
        }
        return true;
    }

    @Override
    public String toString() {
        return "com.mycompany.coretech3.model.PcConfigurations[ id=" + id + " ]";
    }
    
}
