import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from '../header/header.component';
import { FooterComponent } from '../footer/footer.component';
import { ProductcardComponent } from '../productcard/productcard.component';
import { FilterComponent } from '../filter/filter.component';
import { ProductService, Product } from '../services/product.service';

@Component({
  selector: 'app-top50',
  standalone: true,
  imports: [CommonModule, HeaderComponent, FooterComponent, ProductcardComponent, FilterComponent],
  templateUrl: './top50.component.html',
  styleUrl: './top50.component.css',
})
export class Top50Component implements OnInit {
  allTop50Products: Product[] = [];
  filteredProducts: Product[] = [];
  loading: boolean = true;

  // Filter state
  activeFilters: { categories: number[], brands: number[] } = { categories: [], brands: [] };

  constructor(private productService: ProductService) {}

  ngOnInit(): void {
    this.productService.getAllProducts().subscribe({
      next: (products) => {
        this.allTop50Products = this.selectTop50Products(products);
        this.filteredProducts = [...this.allTop50Products];
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading products:', err);
        this.loading = false;
      }
    });
  }

  // Seeded random - 3 naponként ugyanazok a termékek mindenkinél (TOP 50)
  // DIFFERENT SEED than discounts page!
  private selectTop50Products(products: Product[]): Product[] {
    if (products.length === 0) return [];

    // Seed = hányadik 3 napos periódusban vagyunk + 999 offset (ELTÉRŐ a discount-tól!)
    const daysSinceEpoch = Math.floor(Date.now() / (1000 * 60 * 60 * 24));
    let seed = Math.floor(daysSinceEpoch / 3) + 999; // <-- +999 OFFSET!

    // LCG pseudo-random
    const rng = () => {
      seed = (seed * 1664525 + 1013904223) & 0xffffffff;
      return (seed >>> 0) / 0xffffffff;
    };

    // Shuffle
    const shuffled = [...products];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(rng() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }

    // Pontosan 50 termék (vagy kevesebb ha nincs elég)
    const count = Math.min(50, shuffled.length);
    return shuffled.slice(0, count);
  }

  // Filter change event from filter component
  onFilterChange(filterData: { categories: number[], brands: number[] }): void {
    this.activeFilters = filterData;
    this.applyFilters();
  }

  // Apply filters
  private applyFilters(): void {
    let filtered = [...this.allTop50Products];

    // Category filter
    if (this.activeFilters.categories.length > 0) {
      filtered = filtered.filter(product =>
        this.activeFilters.categories.includes(product.categoryId?.id || 0)
      );
    }

    // Brand filter
    if (this.activeFilters.brands.length > 0) {
      filtered = filtered.filter(product =>
        this.activeFilters.brands.includes(product.brandId?.id || 0)
      );
    }

    this.filteredProducts = filtered;
  }
}