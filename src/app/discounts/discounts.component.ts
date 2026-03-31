import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from '../header/header.component';
import { FooterComponent } from '../footer/footer.component';
import { ProductcardComponent } from '../productcard/productcard.component';
import { FilterComponent, FilterData } from '../filter/filter.component';
import { ProductService, Product } from '../services/product.service';
import { DiscountService } from '../services/discount.service';

@Component({
  selector: 'app-discounts',
  standalone: true,
  imports: [CommonModule, HeaderComponent, FooterComponent, ProductcardComponent, FilterComponent],
  templateUrl: './discounts.component.html',
  styleUrls: ['./discounts.component.css']
})
export class DiscountsComponent implements OnInit {
  private productService = inject(ProductService);
  private discountService = inject(DiscountService);

  allDiscountProducts: Product[] = [];
  filteredProducts: Product[] = [];
  loading: boolean = true;

  ngOnInit(): void {
    this.discountService.getDiscountedProducts().subscribe({
      next: (products) => {
        this.allDiscountProducts = products;
        this.filteredProducts = [...this.allDiscountProducts];
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading products:', err);
        this.loading = false;
      }
    });
  }

  onFilterChange(filterData: FilterData): void {
    if (filterData.categories.length === 0 && filterData.brands.length === 0) {
      this.filteredProducts = [...this.allDiscountProducts];
    } else {
      this.filteredProducts = this.allDiscountProducts.filter(product => {
        const categoryMatch = filterData.categories.length === 0 || 
          filterData.categories.includes(product.categoryId?.id || 0);
        const brandMatch = filterData.brands.length === 0 || 
          filterData.brands.includes(product.brandId?.id || 0);
        return categoryMatch && brandMatch;
      });
    }
  }
}