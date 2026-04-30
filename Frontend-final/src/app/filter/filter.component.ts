import { Component, EventEmitter, OnInit, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';

interface Category {
  id: number;
  name: string;
  checked: boolean;
}

interface Brand {
  id: number;
  name: string;
  checked: boolean;
}

export interface FilterData {
  categories: number[];
  brands: number[];
}

@Component({
  selector: 'app-filter',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './filter.component.html',
  styleUrl: './filter.component.css',
})
export class FilterComponent implements OnInit {
  @Output() filterChange = new EventEmitter<FilterData>();

  categories: Category[] = [];
  brands: Brand[] = [];
  
  showCategories: boolean = true;
  showBrands: boolean = true;

  private apiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources';

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.loadCategories();
    this.loadBrands();
  }

  loadCategories(): void {
    this.http.get<any>(`${this.apiUrl}/categories`).subscribe({
      next: (response) => {
        const cats = response.categories || response || [];
        this.categories = cats.map((cat: any) => ({
          id: cat.id,
          name: cat.name,
          checked: false
        }));
      },
      error: (err) => {
        console.error('Error loading categories:', err);
        // Fallback categories
        this.categories = [
          { id: 1, name: 'Videókártya', checked: false },
          { id: 2, name: 'Processzor', checked: false },
          { id: 3, name: 'Alaplap', checked: false },
          { id: 4, name: 'Memória (RAM)', checked: false },
          { id: 5, name: 'Tápegység', checked: false },
          { id: 6, name: 'SSD', checked: false },
          { id: 7, name: 'HDD', checked: false },
          { id: 8, name: 'Gépház', checked: false },
          { id: 9, name: 'Hűtés', checked: false },
          { id: 11, name: 'Egér', checked: false },
          { id: 12, name: 'Billentyűzet', checked: false },
          { id: 13, name: 'Monitor', checked: false },
          { id: 14, name: 'Fejhallgató', checked: false },
          { id: 15, name: 'Egérpad', checked: false },
          { id: 16, name: 'Mikrofon', checked: false }
        ];
      }
    });
  }

  loadBrands(): void {
    this.http.get<any>(`${this.apiUrl}/brands`).subscribe({
      next: (response) => {
        const brs = response.brands || response || [];
        this.brands = brs.map((brand: any) => ({
          id: brand.id,
          name: brand.name,
          checked: false
        }));
      },
      error: (err) => {
        console.error('Error loading brands:', err);
        // Fallback brands
        this.brands = [
          { id: 1, name: 'Intel', checked: false },
          { id: 2, name: 'AMD', checked: false },
          { id: 3, name: 'NVIDIA', checked: false },
          { id: 4, name: 'ASUS', checked: false },
          { id: 5, name: 'MSI', checked: false },
          { id: 6, name: 'Gigabyte', checked: false },
          { id: 7, name: 'Corsair', checked: false },
          { id: 8, name: 'Kingston', checked: false },
          { id: 9, name: 'Samsung', checked: false },
          { id: 10, name: 'Western Digital', checked: false }
        ];
      }
    });
  }

  toggleCategories(): void {
    this.showCategories = !this.showCategories;
  }

  toggleBrands(): void {
    this.showBrands = !this.showBrands;
  }

  onCategoryChange(categoryId: number): void {
    const category = this.categories.find(c => c.id === categoryId);
    if (category) {
      category.checked = !category.checked;
    }
    this.emitFilterChange();
  }

  onBrandChange(brandId: number): void {
    const brand = this.brands.find(b => b.id === brandId);
    if (brand) {
      brand.checked = !brand.checked;
    }
    this.emitFilterChange();
  }

  emitFilterChange(): void {
    const filterData: FilterData = {
      categories: this.categories.filter(c => c.checked).map(c => c.id),
      brands: this.brands.filter(b => b.checked).map(b => b.id)
    };
    this.filterChange.emit(filterData);
  }

  clearFilters(): void {
    this.categories.forEach(c => c.checked = false);
    this.brands.forEach(b => b.checked = false);
    this.emitFilterChange();
  }

  get hasActiveFilters(): boolean {
    return this.categories.some(c => c.checked) || this.brands.some(b => b.checked);
  }
}