import { Component, HostListener, OnInit } from '@angular/core';
import { ShopmenuComponent } from "../shopmenu/shopmenu.component";
import { Router, RouterLink } from "@angular/router";
import { AuthService } from "../services/auth.service";
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.css'],
  imports: [ShopmenuComponent, RouterLink, CommonModule],
})
export class HeaderComponent implements OnInit {
  loginPopup = false;
  shopMenu = false;
  username: string | null = null;

  searchQuery = '';
  showSuggestions = false;
  suggestions = [
    'Videókártya', 'Processzor', 'Memória (RAM)', 'Alaplap',
    'SSD', 'HDD', 'Hűtés', 'Tápegység', 'Gépház',
    'Egér', 'Billentyűzet', 'Monitor', 'Fejhallgató', 'Mikrofon'
  ];
  filteredSuggestions: string[] = [];
  suggestionsHtml = '';

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit() {
    console.log('🔍 Header component initialized');
    
    // Subscribe to user changes from AuthService
    this.authService.currentUser$.subscribe(user => {
      console.log('👤 Current user updated:', user);
      this.username = user?.username || null;
      
      if (this.username) {
        console.log('✅ Username set in header:', this.username);
      } else {
        console.log('⚠️ No username available');
      }
    });

    // Also check localStorage directly as a fallback
    const savedUser = localStorage.getItem('user');
    if (savedUser && !this.username) {
      const user = JSON.parse(savedUser);
      this.username = user.username;
      console.log('📦 Username loaded from localStorage:', this.username);
    }
  }

  navigateToProfile() {
    this.router.navigate(['/profile']);
  }

  logout() {
    this.authService.logout();
    this.username = null;
    this.router.navigate(['/mainpage']);
  }

  toggleShopMenu(){ this.shopMenu = !this.shopMenu; }
  closeShopMenu(){ this.shopMenu = false; }

  onSearch(value: string){
    this.searchQuery = value;
    const q = value.trim().toLowerCase();
    if (!q) {
      this.filteredSuggestions = [];
      this.suggestionsHtml = '';
      this.showSuggestions = false;
      return;
    }
    this.filteredSuggestions = this.suggestions.filter(s => s.toLowerCase().includes(q)).slice(0, 6);
    this.buildSuggestionsHtml();
    this.showSuggestions = this.filteredSuggestions.length > 0;
  }

  openSearch(){
    this.showSuggestions = this.searchQuery.trim().length > 0 && this.filteredSuggestions.length > 0;
  }

  buildSuggestionsHtml(){
    this.suggestionsHtml = this.filteredSuggestions
      .map(s => `<div class="result-item" data-value="${this.escapeHtml(s)}">${this.escapeHtml(s)}</div>`)
      .join('');
  }

  onSuggestionClick(e: MouseEvent){
    const target = (e.target as HTMLElement).closest('.result-item') as HTMLElement | null;
    if (!target) return;
    const val = target.dataset['value'] || target.textContent || '';
    this.selectSuggestion(val);
  }

  selectSuggestion(s: string){
    this.searchQuery = s;
    this.showSuggestions = false;
    this.filteredSuggestions = [];
    this.suggestionsHtml = '';
    
    // Navigate to product page with search query
    this.navigateToProductPage(s);
  }

  onSearchSubmit(event?: Event) {
    if (event) {
      event.preventDefault();
    }
    
    if (this.searchQuery.trim()) {
      this.navigateToProductPage(this.searchQuery);
      this.showSuggestions = false;
    }
  }

  navigateToProductPage(query: string) {
    // Determine category based on search query
    let categoryId = 1; // Default to Graphics Cards
    
    const queryLower = query.toLowerCase();
    if (queryLower.includes('videókártya') || queryLower.includes('grafikus') || 
        queryLower.includes('rtx') || queryLower.includes('gtx') || 
        queryLower.includes('radeon') || queryLower.includes('nvidia') || 
        queryLower.includes('amd')) {
      categoryId = 1; // Graphics Cards
    }
    // Add more category mappings here as needed
    
    // Navigate to product page with search query and category
    this.router.navigate(['/products'], {
      queryParams: {
        search: query,
        category: categoryId
      }
    });
  }

  @HostListener('document:click')
  onDocumentClick(){
    this.showSuggestions = false;
  }

  private escapeHtml(str: string){
    return str.replace(/[&<>"']/g, (m) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]!));
  }
}