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
    this.productService.getAllProducts().subscribe({
      next: (products) => {
        this.allDiscountProducts = this.selectDiscountProducts(products);
        this.filteredProducts = [...this.allDiscountProducts];
        
        const discountIds = this.allDiscountProducts.map(p => p.id);
        this.discountService.setDiscountProducts(discountIds);
        
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

  private selectDiscountProducts(products: Product[]): Product[] {
    if (products.length === 0) return [];

    const daysSinceEpoch = Math.floor(Date.now() / (1000 * 60 * 60 * 24));
    let seed = Math.floor(daysSinceEpoch / 3);

    const rng = () => {
      seed = (seed * 1664525 + 1013904223) & 0xffffffff;
      return (seed >>> 0) / 0xffffffff;
    };

    const shuffled = [...products];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(rng() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }

    const count = Math.min(30 + Math.floor(rng() * 11), shuffled.length);
    return shuffled.slice(0, count);
  }
}