import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { HeaderComponent } from "../header/header.component";
import { FooterComponent } from "../footer/footer.component";
import { CartService } from '../services/cart.service';

interface Game {
  id: number;
  name: string;
  gameType: string;
  requirementLevel: number;
  description: string;
}

interface ConfigProperties {
  cpu?: string;
  gpu?: string;
  ram?: string;
  storage?: string;
  motherboard?: string;
  psu?: string;
  cooler?: string;
  case?: string;
}

interface Configuration {
  id: number;
  name: string;
  description: string;
  budgetMin: number;
  budgetMax: number;
  useCase: string;
  gameTypes: string;
  requirementLevel: number;
  totalPrice: number;
  isFeatured: number;
  productId: number;
  stock: number;
  imageUrl: string;
  price: number;
  properties: ConfigProperties | null;
  productName?: string; // Backend-ből jöhet majd
}

@Component({
  selector: 'app-questionnaire',
  standalone: true,
  imports: [CommonModule, FormsModule, HeaderComponent, FooterComponent],
  templateUrl: './questionnaire.component.html',
  styleUrls: ['./questionnaire.component.css']
})
export class QuestionnaireComponent implements OnInit {
  private apiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources/questionnaire';

  // Wizard step tracking
  currentStep: number = 1;
  
  // Dynamic total steps based on use case
  get totalSteps(): number {
    return this.selectedUseCase === 'gaming' ? 4 : 2;
  }

  // Step 1: Budget
  selectedBudget: string = '';
  budgetOptions = [
    { label: '150 - 350 ezer Ft', value: 'budget_low', min: 150000, max: 350000, icon: 'budget-low' },
    { label: '350 - 550 ezer Ft', value: 'budget_mid', min: 350000, max: 550000, icon: 'budget-mid' },
    { label: '550 ezer Ft felett', value: 'budget_high', min: 550000, max: 2000000, icon: 'budget-high' }
  ];

  // Step 2: Use case
  selectedUseCase: string = '';
  useCaseOptions = [
    { label: 'Gaming', value: 'gaming', icon: 'gaming' },
    { label: 'Videószerkesztés', value: 'video_editing', icon: 'video' },
    { label: 'Programozás', value: 'programming', icon: 'code' },
    { label: 'Általános használat', value: 'all_purpose', icon: 'all' }
  ];

  // Step 3: Game types (conditional - only if gaming)
  selectedGameTypes: string[] = [];
  gameTypeGroups = [
    { type: 'aaa_games', label: 'AAA Játékok', description: 'Cyberpunk, RDR2, Hogwarts Legacy', icon: 'aaa' },
    { type: 'competitive_fps', label: 'Kompetitív FPS', description: 'CS2, Valorant, Apex', icon: 'fps' },
    { type: 'solo_rpg', label: 'Solo RPG', description: 'Witcher 3, Elden Ring, Skyrim', icon: 'rpg' },
    { type: 'indie_casual', label: 'Indie / Casual', description: 'Stardew Valley, Hades, Terraria', icon: 'indie' }
  ];

  // Step 4: Individual games (conditional - only if gaming)
  selectedGameIds: number[] = [];
  availableGames: Game[] = [];
  filteredGames: Game[] = [];
  loadingGames: boolean = false;

  // Results
  showResults: boolean = false;
  loadingResults: boolean = false;
  recommendedConfigurations: Configuration[] = [];

  // Notifications
  showSuccessMessage: boolean = false;
  successMessage: string = '';
  showErrorMessage: boolean = false;
  errorMessage: string = '';

  constructor(
    private http: HttpClient,
    private router: Router,
    private cartService: CartService
  ) {}

  ngOnInit(): void {
    this.loadGames();
  }

  loadGames(): void {
    this.loadingGames = true;
    this.http.get<any>(`${this.apiUrl}/games`).subscribe({
      next: (response) => {
        if (response.status === 'Success') {
          this.availableGames = response.games;
          this.updateFilteredGames();
        }
        this.loadingGames = false;
      },
      error: (err) => {
        console.error('Error loading games:', err);
        this.loadingGames = false;
      }
    });
  }

  // ==================== NAVIGATION ====================
  
  nextStep(): void {
    if (this.currentStep === 1 && !this.selectedBudget) {
      this.showError('Kérlek válassz költségkeretet!');
      return;
    }

    if (this.currentStep === 2 && !this.selectedUseCase) {
      this.showError('Kérlek válassz felhasználási célt!');
      return;
    }

    // Skip to results if not gaming
    if (this.currentStep === 2 && this.selectedUseCase !== 'gaming') {
      this.submitQuestionnaire();
      return;
    }

    if (this.currentStep === 3 && this.selectedGameTypes.length === 0) {
      this.showError('Kérlek válassz legalább egy játék típust!');
      return;
    }

    if (this.currentStep < this.totalSteps) {
      this.currentStep++;
    } else {
      this.submitQuestionnaire();
    }
  }

  prevStep(): void {
    if (this.currentStep > 1) {
      this.currentStep--;
    }
  }

  // ==================== GAME TYPE SELECTION ====================

  toggleGameType(gameType: string): void {
    const index = this.selectedGameTypes.indexOf(gameType);
    if (index > -1) {
      this.selectedGameTypes.splice(index, 1);
    } else {
      this.selectedGameTypes.push(gameType);
    }
    this.updateFilteredGames();
    // Clear selected games when game types change
    this.selectedGameIds = [];
  }

  isGameTypeSelected(gameType: string): boolean {
    return this.selectedGameTypes.includes(gameType);
  }

  updateFilteredGames(): void {
    if (this.selectedGameTypes.length === 0) {
      this.filteredGames = [];
    } else {
      this.filteredGames = this.availableGames.filter(game => 
        this.selectedGameTypes.includes(game.gameType)
      );
    }
  }

  // ==================== GAME SELECTION ====================

  toggleGame(gameId: number): void {
    const index = this.selectedGameIds.indexOf(gameId);
    if (index > -1) {
      this.selectedGameIds.splice(index, 1);
    } else {
      this.selectedGameIds.push(gameId);
    }
  }

  isGameSelected(gameId: number): boolean {
    return this.selectedGameIds.includes(gameId);
  }

  // ==================== SUBMIT & RESULTS ====================

  getSelectedBudgetRange(): { min: number, max: number } {
    const budget = this.budgetOptions.find(b => b.value === this.selectedBudget);
    return budget ? { min: budget.min, max: budget.max } : { min: 0, max: 0 };
  }

  submitQuestionnaire(): void {
    this.loadingResults = true;
    this.showResults = false;

    const budgetRange = this.getSelectedBudgetRange();
    
    let selectedGameIds = '';
    if (this.selectedUseCase === 'gaming' && this.selectedGameIds.length > 0) {
      selectedGameIds = this.selectedGameIds.join(',');
    }

    const requestBody = {
      budgetMin: budgetRange.min,
      budgetMax: budgetRange.max,
      useCase: this.selectedUseCase,
      selectedGameIds: selectedGameIds || undefined
    };

    console.log('📤 Sending request:', requestBody);

    this.http.post<any>(`${this.apiUrl}/recommend`, requestBody).subscribe({
      next: (response) => {
        console.log('📥 Response:', response);
        if (response.status === 'Success') {
          this.recommendedConfigurations = response.configurations;
          this.showResults = true;
        }
        this.loadingResults = false;
      },
      error: (err) => {
        console.error('Error getting recommendations:', err);
        this.loadingResults = false;
        this.showError('Hiba történt az ajánlatok lekérdezése során.');
      }
    });
  }

  // ==================== CART ====================

  addToCart(config: Configuration): void {
    if (!this.cartService.isLoggedIn()) {
      this.showError('A kosárba helyezéshez be kell jelentkezned!');
      this.router.navigate(['/login']);
      return;
    }

    if (config.stock <= 0) {
      this.showError('Sajnos ez a konfiguráció jelenleg nincs raktáron.');
      return;
    }

    // Create product object for cart - must match Product interface
    const product: any = {
      id: config.productId,
      name: config.name,
      price: config.totalPrice,
      pPrice: config.price,
      stock: config.stock,
      imageUrl: config.imageUrl,
      description: config.description
    };

    console.log('🛒 Adding to cart:', product);

    // addToCart returns Observable, need to subscribe!
    this.cartService.addToCart(product, 1).subscribe({
      next: (success) => {
        if (success) {
          this.showSuccess(`${config.name} hozzáadva a kosárhoz!`);
        } else {
          this.showError('Nem sikerült hozzáadni a kosárhoz.');
        }
      },
      error: (err) => {
        console.error('Error adding to cart:', err);
        this.showError('Hiba történt a kosárba helyezés során.');
      }
    });
  }

  // ==================== RESET ====================

  resetQuestionnaire(): void {
    this.currentStep = 1;
    this.selectedBudget = '';
    this.selectedUseCase = '';
    this.selectedGameTypes = [];
    this.selectedGameIds = [];
    this.filteredGames = [];
    this.showResults = false;
    this.recommendedConfigurations = [];
  }

  // ==================== HELPERS ====================

  formatPrice(price: number): string {
    if (!price) return '0 Ft';
    return new Intl.NumberFormat('hu-HU').format(Math.round(price)) + ' Ft';
  }

  getUseCaseLabel(useCase: string): string {
    const labels: { [key: string]: string } = {
      'gaming': 'Gaming',
      'video_editing': 'Videószerkesztés',
      'programming': 'Programozás',
      'all_purpose': 'Általános használat'
    };
    return labels[useCase] || useCase;
  }

  getRequirementLabel(level: number): string {
    const labels: { [key: number]: string } = {
      1: 'Alapszintű',
      2: 'Könnyű',
      3: 'Közepes',
      4: 'Magas',
      5: 'Enthusiast'
    };
    return labels[level] || `${level}/5`;
  }

  getGameTypeName(gameType: string): string {
    const typeNames: { [key: string]: string } = {
      'solo_rpg': 'Solo RPG',
      'competitive_fps': 'Kompetitív FPS',
      'aaa_games': 'AAA játék',
      'indie_casual': 'Indie/Casual'
    };
    return typeNames[gameType] || gameType;
  }

  // Get display name - prefer productName from backend, fallback to properties-based name
  getConfigDisplayName(config: Configuration): string {
    // If backend sends productName, use that
    if (config.productName) {
      return config.productName;
    }
    
    // Otherwise build name from properties
    if (config.properties) {
      const cpu = config.properties.cpu || '';
      const gpu = config.properties.gpu || '';
      
      // Extract short CPU name (e.g., "i5-14600K" from full string)
      const cpuShort = cpu.match(/i[3579]-\d{4,5}[A-Z]?|Ryzen \d \d{4}[X]?/i)?.[0] || '';
      // Extract short GPU name (e.g., "RTX 4060" from full string)
      const gpuShort = gpu.match(/RTX \d{4}( Ti)?|GTX \d{4}|RX \d{4}( XT)?/i)?.[0] || '';
      
      if (cpuShort && gpuShort) {
        return `${cpuShort} + ${gpuShort} Gaming PC`;
      }
    }
    
    // Fallback to original name
    return config.name;
  }

  // Get image URL with fallback placeholder
  getConfigImage(config: Configuration): string {
    if (config.imageUrl && !config.imageUrl.includes('/tmp')) {
      return `http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources/products/${config.productId}/images/1`;
    }
    // Placeholder - SVG data URI for a PC icon
    return 'data:image/svg+xml,' + encodeURIComponent(`
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" fill="none">
        <rect width="100" height="100" fill="#E8EAF3"/>
        <rect x="20" y="15" width="60" height="45" rx="4" stroke="#3D4474" stroke-width="3" fill="white"/>
        <rect x="30" y="25" width="40" height="25" rx="2" fill="#E8EAF3"/>
        <rect x="35" y="65" width="30" height="5" fill="#3D4474"/>
        <rect x="25" y="72" width="50" height="3" rx="1" fill="#3D4474"/>
        <circle cx="70" cy="50" r="3" fill="#3D4474"/>
      </svg>
    `);
  }

  hasProperties(config: Configuration): boolean {
    return config.properties !== null && typeof config.properties === 'object';
  }

  getPropertyEntries(properties: ConfigProperties | null): {key: string, value: string}[] {
    if (!properties) return [];
    
    const labels: { [key: string]: string } = {
      'cpu': 'Processzor',
      'gpu': 'Videókártya',
      'ram': 'Memória',
      'storage': 'Tárhely',
      'motherboard': 'Alaplap',
      'psu': 'Tápegység',
      'cooler': 'Hűtés',
      'case': 'Ház'
    };

    const order = ['cpu', 'gpu', 'ram', 'storage', 'motherboard', 'psu', 'cooler', 'case'];
    
    return order
      .filter(key => properties[key as keyof ConfigProperties])
      .map(key => ({
        key: labels[key] || key,
        value: properties[key as keyof ConfigProperties] || ''
      }));
  }

  // ==================== NOTIFICATIONS ====================

  showSuccess(message: string): void {
    this.successMessage = message;
    this.showSuccessMessage = true;
    setTimeout(() => {
      this.showSuccessMessage = false;
    }, 3000);
  }

  showError(message: string): void {
    this.errorMessage = message;
    this.showErrorMessage = true;
    setTimeout(() => {
      this.showErrorMessage = false;
    }, 3000);
  }
}