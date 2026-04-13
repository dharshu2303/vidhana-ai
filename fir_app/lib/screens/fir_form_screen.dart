import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/translation_service.dart';
import 'fir_draft_screen.dart';

class FirFormScreen extends StatefulWidget {
  final String description;
  final String? originalDescription; 
  final List<String> sections;
  final Map<String, dynamic>? extractedDetails;

  const FirFormScreen({
    super.key,
    required this.description,
    this.originalDescription,
    required this.sections,
    this.extractedDetails,
  });

  @override
  State<FirFormScreen> createState() => _FirFormScreenState();
}

class _FirFormScreenState extends State<FirFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _stationCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fillFromProfile();
      _autoFill();
    });
  }

  void _fillFromProfile() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;
    
    // Default pre-fills from profile if empty
    if (_nameCtrl.text.isEmpty) {
      final profileName = user.complainantName.isNotEmpty ? user.complainantName : user.name;
      if (profileName.isNotEmpty) {
        _nameCtrl.text = profileName;
      }
    }
    if (_stationCtrl.text.isEmpty && user.policeStation.isNotEmpty) {
      _stationCtrl.text = user.policeStation;
    }
  }

  void _autoFill() {
    if (widget.extractedDetails == null) return;
    final det = widget.extractedDetails!;

    final complainantName = det['complainant_name']?.toString() ?? '';
    if (complainantName.isNotEmpty) {
      _nameCtrl.text = _capitalizeFirst(complainantName);
    }
    
    final dateOfOccurrence = det['date_of_occurrence']?.toString() ?? '';
    if (dateOfOccurrence.isNotEmpty) {
      _dateCtrl.text = dateOfOccurrence;
    }
    
    final timeOfOccurrence = det['time_of_occurrence']?.toString() ?? '';
    if (timeOfOccurrence.isNotEmpty) {
      _timeCtrl.text = timeOfOccurrence;
    }
    
    final placeOfOccurrence = det['place_of_occurrence']?.toString() ?? '';
    if (placeOfOccurrence.isNotEmpty) {
      _placeCtrl.text = _capitalizeFirst(placeOfOccurrence);
    }

    final ps = det['police_station']?.toString() ?? '';
    if (ps.isNotEmpty) {
      _stationCtrl.text = _capitalizeFirst(ps);
    }
    
    _translateExtractedDetails();
  }
  
  Future<void> _translateExtractedDetails() async {
    final tr = Provider.of<TranslationService>(context, listen: false);
    if (tr.locale == 'en') return;
    
    final det = widget.extractedDetails!;
    try {
      final complainantName = det['complainant_name']?.toString() ?? '';
      if (complainantName.isNotEmpty) {
        final res = await ApiService.translateText(complainantName, targetLang: tr.locale);
        if (res['translated']?.isNotEmpty == true && mounted) {
           _nameCtrl.text = _capitalizeFirst(res['translated'].toString());
        }
      }
      final dateOfOccurrence = det['date_of_occurrence']?.toString() ?? '';
      if (dateOfOccurrence.isNotEmpty) {
        final res = await ApiService.translateText(dateOfOccurrence, targetLang: tr.locale);
        if (res['translated']?.isNotEmpty == true && mounted) {
           _dateCtrl.text = _capitalizeFirst(res['translated'].toString());
        }
      }
      final timeOfOccurrence = det['time_of_occurrence']?.toString() ?? '';
      if (timeOfOccurrence.isNotEmpty) {
        final res = await ApiService.translateText(timeOfOccurrence, targetLang: tr.locale);
        if (res['translated']?.isNotEmpty == true && mounted) {
           _timeCtrl.text = _capitalizeFirst(res['translated'].toString());
        }
      }
      final placeOfOccurrence = det['place_of_occurrence']?.toString() ?? '';
      if (placeOfOccurrence.isNotEmpty) {
        final res = await ApiService.translateText(placeOfOccurrence, targetLang: tr.locale);
        if (res['translated']?.isNotEmpty == true && mounted) {
           _placeCtrl.text = _capitalizeFirst(res['translated'].toString());
        }
      }
      final ps = det['police_station']?.toString() ?? '';
      if (ps.isNotEmpty) {
        final res = await ApiService.translateText(ps, targetLang: tr.locale);
        if (res['translated']?.isNotEmpty == true && mounted) {
           _stationCtrl.text = _capitalizeFirst(res['translated'].toString());
        }
      }
    } catch (_) {}
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _placeCtrl.dispose();
    _stationCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.surfaceCard,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.surfaceCard,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _timeCtrl.text = picked.format(context);
      });
    }
  }

  Future<void> _generate() async {
    final tr = Provider.of<TranslationService>(context, listen: false);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    
    try {
      String finalName = _nameCtrl.text.trim();
      String finalPlace = _placeCtrl.text.trim();
      String finalStation = _stationCtrl.text.trim();
      
      String finalDesc = widget.description;

      final draft = await ApiService.generateFir(
        complainantName: finalName,
        description: finalDesc,
        sections: widget.sections,
        dateOfOccurrence: _dateCtrl.text.trim().isEmpty
            ? 'Not specified'
            : _dateCtrl.text.trim(),
        timeOfOccurrence: _timeCtrl.text.trim().isEmpty
            ? 'Not specified'
            : _timeCtrl.text.trim(),
        placeOfOccurrence: finalPlace.isEmpty
            ? 'Not specified'
            : finalPlace,
        policeStation: finalStation.isEmpty
            ? 'Not specified'
            : finalStation,
      );
      
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FirDraftScreen(
              draft: draft,
              originalDescription: widget.originalDescription,
              sections: widget.sections,
              complainantName: _nameCtrl.text.trim(),
            ),
          ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = Provider.of<TranslationService>(context);

    return Scaffold(
      appBar: AppBar(title: Text(tr.t('fir_details'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeInDown(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.lightCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr.t('sections_filed'),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      if (widget.sections.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: widget.sections
                              .map((s) => Chip(
                                    label: Text(s.toUpperCase()),
                                  ))
                              .toList(),
                        )
                      else
                        Text(tr.t('no_sections')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              if (widget.extractedDetails != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.accent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(tr.t('auto_filled'),
                              style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),

              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: _buildField(
                    _nameCtrl, tr.t('complainant_name'), Icons.person,
                    isRequired: true, tr: tr),
              ),
              const SizedBox(height: 12),
              
              FadeInUp(
                delay: const Duration(milliseconds: 150),
                child: _buildDatePicker(tr),
              ),
              const SizedBox(height: 12),
              
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _buildTimePicker(tr),
              ),
              const SizedBox(height: 12),
              
              FadeInUp(
                delay: const Duration(milliseconds: 250),
                child: _buildField(
                    _placeCtrl, tr.t('place_occurrence'), Icons.location_on,
                    tr: tr),
              ),
              const SizedBox(height: 12),
              
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: _buildField(
                    _stationCtrl, tr.t('police_station'), Icons.local_police,
                    tr: tr),
              ),
              const SizedBox(height: 24),

              FadeInUp(
                delay: const Duration(milliseconds: 350),
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _generate,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary))
                      : const Icon(Icons.article_rounded),
                  label: Text(
                      _loading ? tr.t('generating') : tr.t('generate_fir')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {bool isRequired = false, required TranslationService tr}) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon),
      ),
      validator: (v) {
        if (isRequired && (v == null || v.trim().isEmpty)) {
          return tr.t('field_required');
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker(TranslationService tr) {
    return TextFormField(
      controller: _dateCtrl,
      readOnly: true,
      onTap: () => _selectDate(context),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: tr.t('date_occurrence'),
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
    );
  }

  Widget _buildTimePicker(TranslationService tr) {
    return TextFormField(
      controller: _timeCtrl,
      readOnly: true,
      onTap: () => _selectTime(context),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: tr.t('time_occurrence'),
        prefixIcon: const Icon(Icons.access_time),
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
    );
  }
}
