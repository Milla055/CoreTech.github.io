import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ProductService, Product } from '../services/product.service';
import { ProductcardComponent } from '../productcard/productcard.component';
import { FilterComponent, FilterData } from '../filter/filter.component';
import { FooterComponent } from "../footer/footer.component";
import { HeaderComponent } from "../header/header.component";

@Component({
  selector: 'app-newproductspage',
  standalone: true,
  imports: [CommonModule, ProductcardComponent, FilterComponent, FooterComponent, HeaderComponent],
  templateUrl: './newproductspage.component.html',
  styleUrls: ['./newproductspage.component.css']
})
export class NewproductspageComponent implements OnInit {
  private productService = inject(ProductService);
  
  allProducts: any[] = [];
  filteredProducts: any[] = [];
  isLoading: boolean = true;

  ngOnInit(): void {
    this.loadNewProducts();
  }

  loadNewProducts(): void {
    this.isLoading = true;
    
    this.productService.getAllProducts().subscribe({
      next: (products) => {
        products.sort((a, b) => {
          const dateA = new Date(a.createdAt || 0).getTime();
          const dateB = new Date(b.createdAt || 0).getTime();
          return dateB - dateA;
        });
        
        this.allProducts = products.slice(0, 30);
        this.filteredProducts = [...this.allProducts];
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading products:', error);
        this.isLoading = false;
      }
    });
  }

  onFilterChange(filterData: FilterData): void {
    if (filterData.categories.length === 0 && filterData.brands.length === 0) {
      this.filteredProducts = [...this.allProducts];
    } else {
      this.filteredProducts = this.allProducts.filter(product => {
        const categoryMatch = filterData.categories.length === 0 || 
          filterData.categories.includes(product.categoryId?.id);
        const brandMatch = filterData.brands.length === 0 || 
          filterData.brands.includes(product.brandId?.id);
        return categoryMatch && brandMatch;
      });
    }
  }
}