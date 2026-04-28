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
@Table(name = "games")
@XmlRootElement
@NamedQueries({
    @NamedQuery(name = "Games.findAll", query = "SELECT g FROM Games g"),
    @NamedQuery(name = "Games.findById", query = "SELECT g FROM Games g WHERE g.id = :id"),
    @NamedQuery(name = "Games.findByName", query = "SELECT g FROM Games g WHERE g.name = :name"),
    @NamedQuery(name = "Games.findByGameType", query = "SELECT g FROM Games g WHERE g.gameType = :gameType"),
    @NamedQuery(name = "Games.findByRequirementLevel", query = "SELECT g FROM Games g WHERE g.requirementLevel = :requirementLevel"),
    @NamedQuery(name = "Games.findByMinCpuScore", query = "SELECT g FROM Games g WHERE g.minCpuScore = :minCpuScore"),
    @NamedQuery(name = "Games.findByMinGpuScore", query = "SELECT g FROM Games g WHERE g.minGpuScore = :minGpuScore"),
    @NamedQuery(name = "Games.findByMinRamGb", query = "SELECT g FROM Games g WHERE g.minRamGb = :minRamGb"),
    @NamedQuery(name = "Games.findByRecommendedStorageType", query = "SELECT g FROM Games g WHERE g.recommendedStorageType = :recommendedStorageType"),
    @NamedQuery(name = "Games.findByCreatedAt", query = "SELECT g FROM Games g WHERE g.createdAt = :createdAt"),
    @NamedQuery(name = "Games.findByIsDeleted", query = "SELECT g FROM Games g WHERE g.isDeleted = :isDeleted"),
    @NamedQuery(name = "Games.findByDeletedAt", query = "SELECT g FROM Games g WHERE g.deletedAt = :deletedAt")})
public class Games implements Serializable {

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
    @Basic(optional = false)
    @NotNull
    @Size(min = 1, max = 15)
    @Column(name = "game_type")
    private String gameType;
    @Basic(optional = false)
    @NotNull
    @Column(name = "requirement_level")
    private short requirementLevel;
    @Column(name = "min_cpu_score")
    private Integer minCpuScore;
    @Column(name = "min_gpu_score")
    private Integer minGpuScore;
    @Column(name = "min_ram_gb")
    private Integer minRamGb;
    @Size(max = 4)
    @Column(name = "recommended_storage_type")
    private String recommendedStorageType;
    @Lob
    @Size(max = 65535)
    @Column(name = "description")
    private String description;
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

    public Games() {
    }

    public Games(Long id) {
        this.id = id;
    }

    public Games(Long id, String name, String gameType, short requirementLevel, Date createdAt) {
        this.id = id;
        this.name = name;
        this.gameType = gameType;
        this.requirementLevel = requirementLevel;
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

    public String getGameType() {
        return gameType;
    }

    public void setGameType(String gameType) {
        this.gameType = gameType;
    }

    public short getRequirementLevel() {
        return requirementLevel;
    }

    public void setRequirementLevel(short requirementLevel) {
        this.requirementLevel = requirementLevel;
    }

    public Integer getMinCpuScore() {
        return minCpuScore;
    }

    public void setMinCpuScore(Integer minCpuScore) {
        this.minCpuScore = minCpuScore;
    }

    public Integer getMinGpuScore() {
        return minGpuScore;
    }

    public void setMinGpuScore(Integer minGpuScore) {
        this.minGpuScore = minGpuScore;
    }

    public Integer getMinRamGb() {
        return minRamGb;
    }

    public void setMinRamGb(Integer minRamGb) {
        this.minRamGb = minRamGb;
    }

    public String getRecommendedStorageType() {
        return recommendedStorageType;
    }

    public void setRecommendedStorageType(String recommendedStorageType) {
        this.recommendedStorageType = recommendedStorageType;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
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
        if (!(object instanceof Games)) {
            return false;
        }
        Games other = (Games) object;
        if ((this.id == null && other.id != null) || (this.id != null && !this.id.equals(other.id))) {
            return false;
        }
        return true;
    }

    @Override
    public String toString() {
        return "com.mycompany.coretech3.model.Games[ id=" + id + " ]";
    }
    
}
